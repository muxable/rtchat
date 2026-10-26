package observability

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"testing"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func testLogger(buffer *bytes.Buffer) *zap.Logger {
	config := zap.NewProductionEncoderConfig()
	config.MessageKey = "message"
	return zap.New(Wrap(zapcore.NewCore(zapcore.NewJSONEncoder(config), zapcore.AddSync(buffer), zap.DebugLevel)), zap.AddCaller(), zap.AddStacktrace(zap.WarnLevel))
}
func readEvent(t *testing.T, buffer *bytes.Buffer) map[string]any {
	t.Helper()
	var event map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buffer.Bytes()), &event); err != nil {
		t.Fatal(err, buffer.String())
	}
	return event
}
func TestReportingPreservesMetricMessageAndScopedErrors(t *testing.T) {
	for _, level := range []zapcore.Level{zap.InfoLevel, zap.WarnLevel, zap.ErrorLevel, zap.DPanicLevel} {
		var buffer bytes.Buffer
		testLogger(&buffer).With(zap.Error(errors.New("original cause"))).Log(level, "http request", zap.Int("status", 500))
		event := readEvent(t, &buffer)
		if event["message"] != "http request" || event["status"] != float64(500) {
			t.Fatal(event)
		}
		if level < zap.WarnLevel {
			if event["@type"] != nil {
				t.Fatal(event)
			}
			continue
		}
		if event["@type"] == nil || event["serviceContext"].(map[string]any)["service"] != "rtchat-agent" || !strings.Contains(event["stack_trace"].(string), "original cause") {
			t.Fatal(event)
		}
		if !strings.Contains(event["stack_trace"].(string), "TestReporting") {
			t.Fatal(event)
		}
	}
}
func panicOrigin() (err error) {
	defer func() {
		if value := recover(); value != nil {
			err = CapturePanic(value)
		}
	}()
	panic("original panic value")
}
func TestRecoveredPanicStack(t *testing.T) {
	var buffer bytes.Buffer
	testLogger(&buffer).Error("handler failed", zap.Error(panicOrigin()))
	event := readEvent(t, &buffer)
	stack := event["stack_trace"].(string)
	if !strings.Contains(stack, "original panic value") || !strings.Contains(stack, "panicOrigin") {
		t.Fatal(stack)
	}
}
func TestHTTPPanic(t *testing.T) {
	var buffer bytes.Buffer
	server := httptest.NewUnstartedServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) { panic("HTTP panic value") }))
	server.Config.ErrorLog = log.New(HTTPLogWriter{testLogger(&buffer)}, "", 0)
	server.Start()
	_, err := server.Client().Get(server.URL)
	server.Close()
	if err == nil {
		t.Fatal("panic should close response")
	}
	event := readEvent(t, &buffer)
	if !strings.Contains(event["stack_trace"].(string), "HTTP panic value") {
		t.Fatal(event)
	}
}

func TestWorkerProcess(t *testing.T) {
	mode := os.Getenv("RTCHAT_TEST_WORKER")
	if mode == "" {
		return
	}
	if err := InstallCrashOutput(); err != nil {
		panic(err)
	}
	switch mode {
	case "panic":
		go func() { panic("background worker panic") }()
		select {}
	case "exit":
		os.Exit(23)
	case "signal":
		_ = syscall.Kill(os.Getpid(), syscall.SIGKILL)
		select {}
	case "ok":
		os.Exit(0)
	case "term":
		ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM)
		defer stop()
		_, _ = os.Stdout.WriteString("ready")
		<-ctx.Done()
		os.Exit(0)
	}
}
func TestSupervisor(t *testing.T) {
	for _, mode := range []string{"panic", "exit", "signal", "ok"} {
		t.Run(mode, func(t *testing.T) {
			var buffer bytes.Buffer
			cmd := exec.Command(os.Args[0], "-test.run=^TestWorkerProcess$")
			cmd.Env = append(os.Environ(), "RTCHAT_TEST_WORKER="+mode)
			cmd.Stderr = io.Discard
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			code := Supervise(ctx, cmd, testLogger(&buffer))
			if mode == "ok" {
				if code != 0 || buffer.Len() != 0 {
					t.Fatal(code, buffer.String())
				}
				return
			}
			if code == 0 {
				t.Fatal("expected failure")
			}
			event := readEvent(t, &buffer)
			if event["@type"] == nil {
				t.Fatal(event)
			}
			if mode == "panic" && !strings.Contains(event["stack_trace"].(string), "background worker panic") {
				t.Fatal(event)
			}
		})
	}
}

type readyWriter struct{ cancel context.CancelFunc }

func (w readyWriter) Write(p []byte) (int, error) { w.cancel(); return len(p), nil }
func TestSupervisorForwardsGracefulShutdown(t *testing.T) {
	var buffer bytes.Buffer
	cmd := exec.Command(os.Args[0], "-test.run=^TestWorkerProcess$")
	cmd.Env = append(os.Environ(), "RTCHAT_TEST_WORKER=term")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd.Stdout = readyWriter{cancel}
	code := Supervise(ctx, cmd, testLogger(&buffer))
	if code != 0 || buffer.Len() != 0 {
		t.Fatal(code, buffer.String())
	}
}
