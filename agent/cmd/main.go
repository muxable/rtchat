package main

import (
	"context"
	"io"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"cloud.google.com/go/compute/metadata"
	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/catalog"
	"github.com/muxable/rtchat/agent/internal/handler"
	"github.com/muxable/rtchat/agent/internal/messagehealth"
	"github.com/muxable/rtchat/agent/internal/oauthhttp"
	"github.com/muxable/rtchat/agent/internal/provider"
	"github.com/muxable/rtchat/agent/internal/publichttp"
	"github.com/muxable/rtchat/agent/internal/subscriptions"
	"github.com/muxable/rtchat/agent/internal/webhook"
	"github.com/muxable/rtchat/agent/internal/youtube"
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

type keyedLock struct {
	mutex sync.Mutex
	users int
}

type KeyedMutex struct {
	mu      sync.Mutex
	mutexes sync.Map
}

func (m *KeyedMutex) Lock(key string) func() {
	m.mu.Lock()
	value, _ := m.mutexes.LoadOrStore(key, &keyedLock{})
	entry := value.(*keyedLock)
	entry.users++
	m.mu.Unlock()
	entry.mutex.Lock()

	return func() {
		entry.mutex.Unlock()
		m.mu.Lock()
		entry.users--
		if entry.users == 0 {
			m.mutexes.Delete(key)
		}
		m.mu.Unlock()
	}
}

func main() {
	if metadata.OnGCE() {
		logger, err := loggerConfig.Build(
			zap.AddStacktrace(zap.ErrorLevel),
		)
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

	ctx, stop := signal.NotifyContext(
		context.Background(),
		os.Interrupt,
		syscall.SIGTERM,
	)
	defer stop()

	client, err := firestore.NewClient(ctx, "rtchat-47692")
	if err != nil {
		zap.L().Fatal(
			"failed to create firestore client",
			zap.Error(err),
		)
	}

	go messagehealth.Run(
		ctx,
		5*time.Minute,
		15*time.Minute,
	)

	defer client.Close()
	stopJobs := startScheduledJobs(ctx, client)
	defer stopJobs()

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
	subscribeRequests := client.Collection("assignments").Snapshots(ctx)

	manager := newRequestManager(func(req *agent.Request) (io.Closer, error) {
		switch req.Provider() {
		case agent.ProviderYouTube:
			return youtube.NewClient(req.Channel(), client)
		default:
			return twitch.NewClient(req)
		}
	})

	go func() {
		ticker := time.NewTicker(15 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				zap.L().Info("active channels", zap.Int("count", manager.count()))
			}
		}
	}()

	isListening := &atomic.Bool{}
	ready := &atomic.Bool{}
	initial := newInitialJoins(func() {
		zap.L().Info("initial channels applied", zap.Int("count", manager.count()))
		ready.Store(true)
	})

	manager.applied = initial.done
	start := time.Now().Add(time.Duration(rand.Intn(24)) * time.Hour)
	recycleHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !ready.Load() || !isListening.Load() || time.Since(start) > 72*time.Hour {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		_, _ = w.Write([]byte((72*time.Hour - time.Since(start)).String()))
	})

	serverErr := make(chan error, 1)

	go func() {
		// Optional webhook credentials must not delay the chat snapshot loop.
		secretsCtx, secretsCancel := context.WithTimeout(
			context.Background(),
			10*time.Second,
		)
		secrets := webhook.LoadSecrets(secretsCtx, nil)
		secretsCancel()

		server := webhook.NewServer(secrets)

		verifier, err := callable.FirebaseVerifier(
			context.Background(),
			"rtchat-47692",
		)
		if err != nil {
			zap.L().Warn(
				"callable authentication unavailable; protected requests will be rejected",
			)
		}

		api := callable.NewServer(verifier)

		registerChat(api, &chatRoutes{
			tokens: provider.NewService(client, nil),
			store:  chatFirestore{DB: client},
		})

		subscriptionService := &subscriptions.Service{
			DB:             client,
			API:            &subscriptions.API{Tokens: provider.NewService(client, &http.Client{Timeout: 10 * time.Second})},
			Enabled:        os.Getenv("AGENT_PROVIDER_SUBSCRIPTIONS_ENABLED") == "true",
			TwitchSecret:   secrets.TwitchEventSubSecret,
			MaticWebhookID: secrets.AlchemyMaticWebhookID,
		}

		subscriptionService.Register(api)
		catalog.Register(api, client, provider.NewService(client, nil))

		// Register every callable package before Mount so readiness and webhooks remain intact.
		api.Mount(server.Mux)

		if err := publichttp.Register(
			server.Mux,
			client,
			provider.NewService(client, nil),
		); err != nil {
			zap.L().Warn("public HTTP configuration invalid; routes disabled")
			for _, path := range []string{
				"/embed",
				"/embedRedirect",
				"/metadata",
				"/api/metadata",
			} {
				server.Mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
					http.Error(
						w,
						"temporarily unavailable",
						http.StatusServiceUnavailable,
					)
				})
			}
		}

		server.RegisterProvider(
			"/kick/",
			webhook.NewKickHandler(webhook.NewKickFirestoreStore(client)),
		)

		server.RegisterProvider(
			"/twitch/",
			webhook.NewTwitchHandler(
				secrets.TwitchEventSubSecret,
				client,
				twitchClientID,
				twitchClientSecret,
			),
		)

		server.RegisterProvider(
			"/alchemy/",
			webhook.NewAlchemyHandler(
				webhook.AlchemyConfig{
					Secrets:        secrets,
					MaticWebhookID: secrets.AlchemyMaticWebhookID,
				},
				webhook.AlchemyFirestore{Client: client},
				webhook.NewAlchemyRPC(),
			),
		)

		if os.Getenv("ENABLE_AGENT_OAUTH") == "true" {
			oauthCtx, oauthCancel := context.WithTimeout(
				context.Background(),
				30*time.Second,
			)
			if err := oauthhttp.Register(oauthCtx, server.Mux, client); err != nil {
				zap.L().Warn("OAuth HTTP unavailable", zap.Error(err))
			}
			oauthCancel()
		}

		server.Mux.Handle(
			"/health/messages",
			messagehealth.Handler(15*time.Minute),
		)

		server.Mux.Handle("/", recycleHandler)

		port := os.Getenv("PORT")
		if port == "" {
			port = "8080"
		}

		httpServer := &http.Server{
			Addr:              ":" + port,
			Handler:           server.Mux,
			ReadHeaderTimeout: 10 * time.Second,
		}

		// Shut down the HTTP server when the application context is cancelled.
		go func() {
			<-ctx.Done()

			shutdownCtx, shutdownCancel := context.WithTimeout(
				context.Background(),
				10*time.Second,
			)
			defer shutdownCancel()

			if err := httpServer.Shutdown(shutdownCtx); err != nil {
				zap.L().Error("HTTP server shutdown failed", zap.Error(err))
			}
		}()

		zap.L().Info("starting http server", zap.String("port", port))

		if err := httpServer.ListenAndServe(); err != nil &&
			err != http.ErrServerClosed {
			select {
			case serverErr <- err:
			default:
			}
		}
	}()

	// A server failure should cancel the application instead of calling Fatal
	// from the server goroutine, allowing deferred cleanup to run.
	go func() {
		select {
		case err := <-serverErr:
			zap.L().Error("HTTP server failed", zap.Error(err))
			stop()
		case <-ctx.Done():
		}
	}()

	first := true

	for {
		if ctx.Err() != nil {
			return
		}

		isListening.Store(true)
		snapshot, err := subscribeRequests.Next()
		isListening.Store(false)

		if err != nil {
			if ctx.Err() == nil {
				zap.L().Error("assignment snapshot listener failed", zap.Error(err))
				stop()
			}
			return
		}

		for _, change := range snapshot.Changes {
			req := (*agent.Request)(change.Doc.Ref)
			zap.L().Info("got request", zap.String("id", req.String()))

			if first {
				initial.add(req.String())
			}

			manager.submit(req, change.Kind)

			select {
			case <-ctx.Done():
				return
			case <-time.After(250 * time.Millisecond):
			}
		}

		if first {
			first = false
			initial.seal()
		}
	}

}
