package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/google/uuid"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/handler"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"golang.org/x/sync/errgroup"
)

func NewGCPLogger() (*zap.Logger, error) {
    loggerCfg := &zap.Config{
		Level:            zap.NewAtomicLevelAt(zapcore.InfoLevel),
		Encoding:         "json",
		EncoderConfig:    encoderConfig,
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
    }

	return loggerCfg.Build(zap.AddStacktrace(zap.DPanicLevel))
}


var encoderConfig = zapcore.EncoderConfig{
	TimeKey:        "time",
	LevelKey:       "severity",
	NameKey:        "logger",
	CallerKey:      "caller",
	MessageKey:     "message",
	StacktraceKey:  "stacktrace",
	LineEnding:     zapcore.DefaultLineEnding,
	EncodeLevel:    encodeLevel(),
	EncodeTime:     zapcore.RFC3339TimeEncoder,
	EncodeDuration: zapcore.MillisDurationEncoder,
	EncodeCaller:   zapcore.ShortCallerEncoder,
}

func encodeLevel() zapcore.LevelEncoder {
	return func(l zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {
		switch l {
		case zapcore.DebugLevel:
			enc.AppendString("DEBUG")
		case zapcore.InfoLevel:
			enc.AppendString("INFO")
		case zapcore.WarnLevel:
			enc.AppendString("WARNING")
		case zapcore.ErrorLevel:
			enc.AppendString("ERROR")
		case zapcore.DPanicLevel:
			enc.AppendString("CRITICAL")
		case zapcore.PanicLevel:
			enc.AppendString("ALERT")
		case zapcore.FatalLevel:
			enc.AppendString("EMERGENCY")
		}
	}
}

func quitContext() context.Context {
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	preemption := make(chan struct{})
	go func() {
		req, err := http.NewRequest("GET", "http://metadata.google.internal/computeMetadata/v1/instance/preempted?wait_for_change=true", nil)
		if err != nil {
			zap.L().Warn("failed to create preemption request", zap.Error(err))
			return
		}
		req.Header.Add("Metadata-Flavor", "Google")
		for {
			res, err := http.DefaultClient.Do(req)
			if err != nil {
				if os.IsTimeout(err) {
					continue
				}
				zap.L().Warn("failed to send preemption request", zap.Error(err))
				return
			}
			if res.StatusCode != http.StatusOK {
				zap.L().Warn("preemption request failed", zap.Int("status", res.StatusCode))
				continue
			}
			close(preemption)
		}
	}()

	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		select {
		case <-preemption:
			zap.L().Info("instance is being preempted")
			cancel()
			break
		case <-sigs:
			zap.L().Info("received termination signal")
			cancel()
			break
		}
	}()

	http.HandleFunc("/quitquitquit", func(w http.ResponseWriter, r *http.Request) {
		zap.L().Info("received quitquitquit request")
		cancel()
		w.Write([]byte("ok"))
	})

	return ctx
}

func fetchAgentID() (agent.AgentID, error) {
	req, err := http.NewRequest("GET", "http://metadata.google.internal/computeMetadata/v1/instance/id", nil)
	if err != nil {
		return "", err
	}
	req.Header.Add("Metadata-Flavor", "Google")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to get instance id: %d", res.StatusCode)
	}
	defer res.Body.Close()
	
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}
	return agent.AgentID(body), nil
}

func main() {
	agentID, err := fetchAgentID()
	if err != nil {
		logger, err := zap.NewDevelopment()
		if err != nil {
			panic(err)
		}
		defer logger.Sync()
		agentID = agent.AgentID(fmt.Sprintf("pseudo:%s", uuid.New().String()))
		undo := zap.ReplaceGlobals(logger.With(zap.String("agentId", string(agentID))))
		defer undo()
		zap.L().Warn("failed to fetch agent id", zap.Error(err))
	} else {
		logger, err := NewGCPLogger()
		if err != nil {
			panic(err)
		}
		defer logger.Sync()
		undo := zap.ReplaceGlobals(logger.With(zap.String("agentId", string(agentID))))
		defer undo()
	}

	// don't use the application context because we will perform cleanup on SIGINT/SIGTERM
	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	terminateCtx, terminate := context.WithCancel(quitContext())

	go agent.RunWatchdog(terminateCtx, agentID, client)

	// create a new RequestLock
	lock := agent.NewRequestLock(terminateCtx, agentID, client)

	handler, err := handler.NewHandler(lock, client)
	if err != nil {
		zap.L().Fatal("failed to create handler", zap.Error(err))
	}

	activeChannels := &sync.Map{}

	go func() {
		for {
			done := false
			select {
			case <-terminateCtx.Done():
				done = true
			case <-time.After(15 * time.Second):
			}
			chs := make([]string, 0)
			activeChannels.Range(func(key, value interface{}) bool {
				chs = append(chs, key.(string))
				return true
			})
			zap.L().Info("active channels", zap.Strings("channels", chs))
			if done {
				break
			}
		}
	}()

	isListening := &atomic.Bool{}

	http.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !isListening.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Write([]byte("ok"))
	}))

	go func() {
		zap.L().Info("starting http server")
		if err := http.ListenAndServe(":8082", nil); err != nil {
			zap.L().Fatal("failed to start http server", zap.Error(err))
		}
	}()

	var errwg errgroup.Group

	for {
		isListening.Store(true)
		req, err := lock.Next()
		isListening.Store(false)
		if err != nil {
			if !errors.Is(err, context.Canceled) {
				zap.L().Error("failed to get next request", zap.Error(err))
			}
			terminate()
			break
		}
		zap.L().Info("got request", zap.String("id", req.String()))
		// check if it's in the active channels map
		if _, loaded := activeChannels.LoadOrStore(req.String(), struct{}{}); loaded {
			zap.L().Info("request already active", zap.String("id", req.String()))
			continue
		}

		errwg.Go(func() error {
			defer activeChannels.Delete(req.String())

			joinCtx, err := handler.Join(req)
			if err != nil {
				zap.L().Error("failed to open request", zap.Error(err))
				return nil
			}

			// lock the request
			claim, err := agent.LockClaim(req)
			if err != nil {
				if errors.Is(err, context.Canceled) {
					return nil
				}
				return fmt.Errorf("failed to lock request: %w", err)
			}

			go func() {
				select {
				case <-joinCtx.ReconnectCtx.Done():
					break
				case <-terminateCtx.Done():
					break
				}
				if err := claim.Unlock(); err != nil {
					zap.L().Error("failed to unlock request", zap.Error(err))
				}
			}()

			if err := claim.Wait(); err != nil {
				zap.L().Error("failed to wait for request lock", zap.Error(err))
			}

			// leave
			if err := joinCtx.Close(); err != nil {
				zap.L().Error("failed to leave request", zap.Error(err))
			}

			// call unlock again to ensure it's unlocked
			if err := claim.Unlock(); err != nil {
				return fmt.Errorf("failed to unlock request: %w", err)
			}

			return nil
		})
	}

	if err := errwg.Wait(); err != nil {
		zap.L().Error("failed to join request", zap.Error(err))
	}
}
