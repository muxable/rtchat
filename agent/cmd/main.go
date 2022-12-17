package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"sync"
	"sync/atomic"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/google/uuid"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/handler"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
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

	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	go agent.RunWatchdog(context.Background(), agentID, client)

	// create a new RequestLock
	lock := agent.NewRequestLock(context.Background(), agentID, client)

	handler, err := handler.NewHandler(lock, client)
	if err != nil {
		zap.L().Fatal("failed to create handler", zap.Error(err))
	}

	activeChannels := &sync.Map{}

	go func() {
		ticker := time.NewTicker(15 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			chs := make([]string, 0)
			activeChannels.Range(func(key, value interface{}) bool {
				chs = append(chs, key.(string))
				return true
			})
			zap.L().Info("active channels", zap.Strings("channels", chs))
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
		port := os.Getenv("PORT")
		if port == "" {
			port = "8080"
		}
		if err := http.ListenAndServe(":" + port, nil); err != nil {
			zap.L().Fatal("failed to start http server", zap.Error(err))
		}
	}()

	for {
		isListening.Store(true)
		req, err := lock.Next()
		isListening.Store(false)
		if err != nil {
			zap.L().Error("failed to get next request", zap.Error(err))
			break
		}
		zap.L().Info("got request", zap.String("id", req.String()))
		// check if it's in the active channels map
		if _, loaded := activeChannels.LoadOrStore(req.String(), struct{}{}); loaded {
			zap.L().Info("request already active", zap.String("id", req.String()))
			continue
		}
		go func() {
			if err := handler.Join(req); err != nil {
				zap.L().Error("failed to open request", zap.Error(err))
				return
			}
		}()
		time.Sleep(500 * time.Millisecond)
	}
}
