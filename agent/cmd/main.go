package main

import (
	"context"
	"io"
	"math/rand"
	"net/http"
	"os"
	"sync"
	"sync/atomic"
	"time"

	"cloud.google.com/go/compute/metadata"
	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/handler"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var loggerConfig = &zap.Config{
	Level:    zap.NewAtomicLevelAt(zapcore.InfoLevel),
	Encoding: "json",
	EncoderConfig: zapcore.EncoderConfig{
		TimeKey:       "time",
		LevelKey:      "severity",
		NameKey:       "logger",
		CallerKey:     "caller",
		MessageKey:    "message",
		StacktraceKey: "stacktrace",
		LineEnding:    zapcore.DefaultLineEnding,
		EncodeLevel: func(l zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {
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
		},
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.MillisDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	},
	OutputPaths:      []string{"stdout"},
	ErrorOutputPaths: []string{"stderr"},
}

type KeyedMutex struct {
	mutexes sync.Map // Zero value is empty and ready for use
}

func (m *KeyedMutex) Lock(key string) func() {
	value, _ := m.mutexes.LoadOrStore(key, &sync.Mutex{})
	mtx := value.(*sync.Mutex)
	mtx.Lock()

	return func() { mtx.Unlock() }
}

func main() {
	if metadata.OnGCE() {
		logger, err := loggerConfig.Build(zap.AddStacktrace(zap.ErrorLevel))
		if err != nil {
			panic(err)
		}
		defer logger.Sync()
		undo := zap.ReplaceGlobals(logger)
		defer undo()
	} else {
		logger, err := zap.NewDevelopment()
		if err != nil {
			panic(err)
		}
		defer logger.Sync()
		undo := zap.ReplaceGlobals(logger)
		defer undo()
	}

	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	twitchClientID := auth.TwitchClientID()
	twitchClientSecret, err := auth.TwitchClientSecret()
	if err != nil {
		zap.L().Fatal("failed to get twitch client secret", zap.Error(err))
	}

	twitch := &handler.TwitchAgent{
		Firestore:    client,
		ClientID:     twitchClientID,
		ClientSecret: twitchClientSecret,
	}

	// create a new RequestLock
	subscribeRequests := client.Collection("assignments").Snapshots(context.Background())

	clients := map[string]io.Closer{}
	locks := &KeyedMutex{}

	go func() {
		ticker := time.NewTicker(15 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			zap.L().Info("active channels", zap.Int("count", len(clients)))
		}
	}()

	isListening := &atomic.Bool{}
	start := time.Now().Add(time.Duration(rand.Intn(24)) * time.Hour)
	http.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !isListening.Load() || time.Since(start) > 72*time.Hour {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Write([]byte((72*time.Hour - time.Since(start)).String()))
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
		snapshot, err := subscribeRequests.Next()
		isListening.Store(false)
		if err != nil {
			return
		}
		for _, change := range snapshot.Changes {
			if change.Kind != firestore.DocumentRemoved {
				req := (*agent.Request)(change.Doc.Ref)
				zap.L().Info("got request", zap.String("id", req.String()))
				// check if it's in the active channels map
				go func() {
					unlock := locks.Lock(req.String())
					defer unlock()
					existing := clients[req.String()]
					switch req.Provider() {
					case agent.ProviderTwitch:
						switch existing.(type) {
						case *handler.AuthenticatedTwitchClient:
							// skip upgrade with 75% probability
							if rand.Intn(4) != 0 {
								zap.L().Info("already authenticated", zap.String("id", req.String()))
								return
							}
						}
						client, err := twitch.NewClient(req)
						if err != nil {
							zap.L().Error("failed to open request", zap.Error(err))
							return
						}
						clients[req.String()] = client
					}
					if existing != nil {
						if err := existing.Close(); err != nil {
							zap.L().Error("failed to close request", zap.Error(err))
						}
					}
				}()
				time.Sleep(250 * time.Millisecond)
			}
		}
	}
}
