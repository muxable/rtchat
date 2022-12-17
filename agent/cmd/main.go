package main

import (
	"context"
	"net/http"
	"os"
	"sync"
	"sync/atomic"
	"time"

	"cloud.google.com/go/firestore"
	"cloud.google.com/go/logging"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/handler"
	stackdriver "github.com/yanolab/stackdriver-zaplogger"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func main() {
	logclient, err := logging.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		panic(err)
	}
	logger := zap.New(zapcore.NewTee(
		stackdriver.NewCore(logclient, zap.DebugLevel),
		zapcore.NewCore(zapcore.NewConsoleEncoder(zap.NewDevelopmentEncoderConfig()), zapcore.AddSync(os.Stdout), zap.InfoLevel),
	))
	defer logger.Sync()
	undo := zap.ReplaceGlobals(logger)
	defer undo()

	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	// create a new RequestLock
	lock := agent.NewRequestLock(context.Background(), client)

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
		if err := http.ListenAndServe(":"+port, nil); err != nil {
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
