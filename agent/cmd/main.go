package main

import (
	"context"
	"errors"
	"fmt"
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
	"golang.org/x/sync/errgroup"
)

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

	return ctx
}

func main() {
	agentID := agent.AgentID(uuid.New().String())

	logger, err := zap.NewDevelopment()
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	undo := zap.ReplaceGlobals(logger.With(zap.String("agentId", string(agentID))))
	defer undo()

	// don't use the application context because we will perform cleanup on SIGINT/SIGTERM
	client, err := firestore.NewClient(context.Background(), "rtchat-47692")
	if err != nil {
		zap.L().Fatal("failed to create firestore client", zap.Error(err))
	}

	terminateCtx, terminate := context.WithCancel(quitContext())

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
		if isListening.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Write([]byte("ok"))
	}))

	go http.ListenAndServe(":8080", nil)

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
		if _, ok := activeChannels.Load(req.String()); ok {
			zap.L().Info("request already active", zap.String("id", req.String()))
			continue
		}

		joinCtx, err := handler.Join(req)
		if err != nil {
			zap.L().Error("failed to open request", zap.Error(err))
			continue
		}

		// add the channel to the active channels map
		activeChannels.Store(req.String(), struct{}{})

		errwg.Go(func() error {
			defer activeChannels.Delete(req.String())

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
