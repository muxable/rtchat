package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/cancel"
	"github.com/muxable/rtchat/agent/internal/handler"
	"go.uber.org/zap"
)

func signalContext() context.Context {
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
		case signal := <-sigs:
			zap.L().Info("received signal", zap.String("signal", signal.String()))
			cancel()
		case <-preemption:
			zap.L().Info("instance was preempted")
			cancel()
		}
	}()
	return ctx
}

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	undo := zap.ReplaceGlobals(logger)
	defer undo()
	
	// don't use the application context because we will perform cleanup on SIGINT/SIGTERM
	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	// create a new RequestLock
	lock := agent.NewRequestLock(signalContext(), client)

	handler, err := handler.NewHandler(lock, client)
	if err != nil {
		zap.L().Fatal("failed to create handler", zap.Error(err))
	}

	// register a callback to be called when a new request is available
	lock.OnRequest(func(req *agent.Request) {
		zap.L().Info("got request", zap.String("id", req.String()))
		if err := handler.HandleRequest(req); err != nil {
			zap.L().Error("failed to handle request", zap.Error(err))
		}
	})

	zap.L().Info("starting agent", zap.String("agentId", string(lock.AgentID)))

	// start the lock
	if err := lock.ListenForRequests(); err != nil {
		if cancel.IsCanceled(err) {
			zap.L().Info("agent was canceled")
		} else {
			zap.L().Fatal("failed to listen for requests", zap.Error(err))
		}
	}
}