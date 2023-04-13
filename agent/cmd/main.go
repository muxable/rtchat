package main

import (
	"context"
	"fmt"
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
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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
	sendRequests := client.Collection("actions").Where("sentAt", "==", nil).Snapshots(context.Background())

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
		w.Write([]byte((72 * time.Hour - time.Since(start)).String()))
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

	go func() {
		for {
			snapshot, err := sendRequests.Next()
			if err != nil {
				zap.L().Error("failed to get send requests", zap.Error(err))
				return
			}
			for _, change := range snapshot.Changes {
				if change.Kind == firestore.DocumentAdded {
					var action struct {
						ChannelId      string
						Message        string
						TargetChannel  string
						ReplyMessageId string
						CreatedAt	  time.Time
					}
					if err := change.Doc.DataTo(&action); err != nil {
						zap.L().Error("failed to unmarshal action", zap.Error(err))
						continue
					}
					if time.Since(action.CreatedAt) > 5 * time.Minute {
						zap.L().Warn("action is too old, skipping", zap.Any("action", action))
						continue
					}
					zap.L().Info("new action", zap.Any("action", change.Doc.Data()))

					// get the username from the channel id
					channel, err := client.Collection("channels").Doc(action.ChannelId).Get(context.Background())
					if err != nil {
						zap.L().Error("failed to get channel", zap.Error(err))
						continue
					}
					// TODO: this only works for twitch. we need to support other platforms
					key := fmt.Sprintf("twitch:%s", channel.Data()["login"])

					unlock := locks.Lock(key)
					client, ok := clients[key]
					if !ok {
						zap.L().Warn("no client found for channel", zap.String("channelId", key))
						unlock()
						continue
					}

					if _, err := change.Doc.Ref.Update(context.Background(), []firestore.Update{
						{Path: "sentAt", Value: firestore.ServerTimestamp},
					}, firestore.LastUpdateTime(change.Doc.UpdateTime)); err != nil {
						if status.Code(err) != codes.FailedPrecondition {
							zap.L().Error("failed to update action", zap.Error(err))
						}
						unlock()
						continue
					}

					zap.L().Info("sending message", zap.String("channelId", key), zap.Any("message", change.Doc.Data()), zap.String("targetChannel", action.TargetChannel))
					switch client := client.(type) {
					case *handler.AuthenticatedTwitchClient:
						if action.ReplyMessageId != "" {
							client.Reply(action.TargetChannel, action.ReplyMessageId, action.Message)
						} else {
							client.Say(action.TargetChannel, action.Message)
						}
					default:
						zap.L().Error("unknown client type", zap.String("channelId", action.ChannelId))
						// revert the action
						if _, err := change.Doc.Ref.Update(context.Background(), []firestore.Update{
							{Path: "sentAt", Value: nil},
						}); err != nil {
							zap.L().Error("failed to revert action", zap.Error(err))
						}
						unlock()
						continue
					}

					// set isComplete to true
					if _, err := change.Doc.Ref.Update(context.Background(), []firestore.Update{
						{Path: "isComplete", Value: true},
					}); err != nil {
						zap.L().Error("failed to update action", zap.Error(err))
					}
					unlock()
				}
			}
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
							// we don't need to upgrade.
							zap.L().Info("already authenticated", zap.String("id", req.String()))
							return
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
