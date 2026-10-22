package youtube

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sync"
	"sync/atomic"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/messagehealth"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type counters struct {
	requests, rateLimits, parseFailures, skipped atomic.Int64
	// unrecognizedPages counts /live pages that are neither live nor offline.
	unrecognizedPages atomic.Int64
}

// Client owns polling and lease renewal. Close joins all of its goroutines.
type Client struct {
	channel string
	owner   string
	baseURL string
	http    HTTPClient
	store   Store

	pollInterval     time.Duration
	metadataInterval time.Duration
	acquireInterval  time.Duration
	renewInterval    time.Duration
	leaseTTL         time.Duration
	retryInitial     time.Duration
	retryMax         time.Duration
	minPoll          time.Duration
	maxPoll          time.Duration

	counts    counters
	ctx       context.Context
	cancel    context.CancelFunc
	done      chan struct{}
	closeOnce sync.Once
}

var _ io.Closer = (*Client)(nil)

func NewClient(channel string, firestoreClient *firestore.Client) (*Client, error) {
	if channel == "" || firestoreClient == nil {
		return nil, fmt.Errorf("YouTube channel and Firestore client are required")
	}
	c, err := newClient(channel, &http.Client{Timeout: 30 * time.Second}, &FirestoreStore{Client: firestoreClient})
	if err != nil {
		return nil, err
	}
	c.start()
	return c, nil
}

// Separate construction from start so tests can substitute endpoints and timing.
func newClient(channel string, httpClient HTTPClient, store Store) (*Client, error) {
	var random [16]byte
	if _, err := rand.Read(random[:]); err != nil {
		return nil, err
	}
	return &Client{channel: channel, owner: hex.EncodeToString(random[:]), baseURL: "https://www.youtube.com", http: httpClient, store: store,
		pollInterval: 3 * time.Minute, metadataInterval: time.Minute, acquireInterval: time.Minute, renewInterval: 30 * time.Second, leaseTTL: 90 * time.Second,
		retryInitial: time.Second, retryMax: 5 * time.Minute, minPoll: time.Second, maxPoll: 30 * time.Second}, nil
}
func (c *Client) start() {
	c.ctx, c.cancel = context.WithCancel(context.Background())
	c.done = make(chan struct{})
	go func() { defer close(c.done); c.run() }()
}
func (c *Client) Close() error {
	c.closeOnce.Do(func() {
		c.cancel()
		<-c.done
	})
	return nil
}
func wait(ctx context.Context, delay time.Duration) bool {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-timer.C:
		return true
	}
}
func (c *Client) nextBackoff(delay time.Duration) time.Duration {
	if delay >= c.retryMax/2 {
		return c.retryMax
	}
	return delay * 2
}
func (c *Client) logCounts() {
	zap.L().Info("YouTube reader counters", zap.String("channel", c.channel), zap.Int64("requests", c.counts.requests.Load()), zap.Int64("429s", c.counts.rateLimits.Load()), zap.Int64("parseFailures", c.counts.parseFailures.Load()), zap.Int64("unrecognizedPages", c.counts.unrecognizedPages.Load()), zap.Int64("skippedActions", c.counts.skipped.Load()))
}
func (c *Client) acquire(ctx context.Context) (bool, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	now := time.Now()
	return c.store.Acquire(ctx, c.channel, c.owner, now, now.Add(c.leaseTTL))
}
func (c *Client) run() {
	loggerDone := make(chan struct{})
	go func() {
		defer close(loggerDone)
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-c.ctx.Done():
				return
			case <-ticker.C:
				c.logCounts()
			}
		}
	}()
	defer func() { c.cancel(); <-loggerDone; c.logCounts() }()
	delay := c.retryInitial
	for c.ctx.Err() == nil {
		acquired, err := c.acquire(c.ctx)
		if err != nil {
			zap.L().Warn("YouTube lease acquisition failed", zap.Error(err))
			if !wait(c.ctx, delay) {
				return
			}
			delay = c.nextBackoff(delay)
			continue
		}
		delay = c.retryInitial
		if acquired {
			c.ownedSession()
		}
		if !wait(c.ctx, c.acquireInterval) {
			return
		}
	}
}
func (c *Client) ownedSession() {
	ctx, cancel := context.WithCancel(c.ctx)
	heartbeatDone := make(chan struct{})
	go func() {
		defer close(heartbeatDone)
		ticker := time.NewTicker(c.renewInterval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				acquired, err := c.acquire(ctx)
				if err != nil || !acquired {
					zap.L().Warn("YouTube reader lost lease", zap.String("channel", c.channel), zap.Error(err))
					cancel()
					return
				}
			}
		}
	}()
	c.read(ctx)
	cancel()
	<-heartbeatDone
	releaseCtx, releaseCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer releaseCancel()
	if err := c.store.Release(releaseCtx, c.channel, c.owner); err != nil {
		zap.L().Warn("YouTube lease release failed", zap.Error(err))
	}
}
func (c *Client) retryWrite(ctx context.Context, write func() error) bool {
	delay := c.retryInitial
	for ctx.Err() == nil {
		err := write()
		if err == nil || status.Code(err) == codes.AlreadyExists {
			return true
		}
		zap.L().Warn("YouTube write failed", zap.Error(err))
		if !wait(ctx, delay) {
			return false
		}
		delay = c.nextBackoff(delay)
	}
	return false
}
func (c *Client) read(ctx context.Context) {
	delay := c.retryInitial
	for ctx.Err() == nil {
		body, err := c.request(ctx, http.MethodGet, "/channel/"+url.PathEscape(c.channel)+"/live", nil)
		video := ""
		if err == nil {
			video, err = liveVideoID(body)
			if errors.As(err, new(*unrecognizedPageError)) {
				// Not knowing is not offline: keep the channel's state and retry.
				c.counts.unrecognizedPages.Add(1)
				zap.L().Error("YouTube /live page unrecognized; channel state unknown", zap.String("channel", c.channel), zap.Int64("unrecognizedPages", c.counts.unrecognizedPages.Load()), zap.Error(err))
			}
		}
		if err == nil && video != "" {
			var page chatPage
			var key, version string
			page, key, version, err = c.initial(ctx, video)
			if err == nil {
				stillLive := c.session(ctx, video, key, version, page, body)
				if ctx.Err() != nil {
					return
				}
				if stillLive {
					// Chat stopped but the stream did not; rediscover it later.
					delay = c.retryInitial
					if !wait(ctx, c.pollInterval) {
						return
					}
					continue
				}
				body = nil // The page shows the ended stream, not the channel.
			}
		}
		if err != nil {
			if !errors.As(err, new(*unrecognizedPageError)) {
				zap.L().Warn("YouTube discovery failed", zap.String("channel", c.channel), zap.Error(err))
			}
			if !wait(ctx, delay) {
				return
			}
			delay = c.nextBackoff(delay)
			continue
		}
		// An offline channel's page still names it.
		var info streamInfo
		if body != nil {
			info, _ = pageInfo(body)
			info.Title, info.Category = nil, nil
		}
		offline := c.channelFields(info, nil)
		if !c.retryWrite(ctx, func() error { return c.store.Merge(ctx, "youtube:"+c.channel, offline) }) {
			return
		}
		delay = c.retryInitial
		if !wait(ctx, c.pollInterval) {
			return
		}
	}
}
func (c *Client) stream(ctx context.Context, video, key, version string, page chatPage) {
	for ctx.Err() == nil {
		for _, raw := range page.Actions {
			data := actionData(c.channel, video, raw, time.Now())
			if data == nil {
				c.counts.skipped.Add(1)
				continue
			}
			id := "youtube:" + data["event"].(map[string]interface{})["id"].(string)
			if data["type"] == "youtube.tombstone" {
				// the tombstone keeps the deleted message's id in its event, but
				// needs its own document or the create is a no-op.
				id += ":tombstone"
			}
			if !c.retryWrite(ctx, func() error {
				return c.store.Create(ctx, "youtube:"+c.channel, id, data)
			}) {
				return
			}

			messagehealth.MarkMessageReceived()
		}
		token, timeout := page.next()
		if token == "" {
			return
		}
		if timeout < c.minPoll {
			timeout = c.minPoll
		}
		if timeout > c.maxPoll {
			timeout = c.maxPoll
		}
		if !wait(ctx, timeout) {
			return
		}
		delay := c.retryInitial
		for ctx.Err() == nil {
			next, err := c.poll(ctx, key, version, token)
			if err == nil {
				page = next
				break
			}
			zap.L().Warn("YouTube poll failed", zap.String("channel", c.channel), zap.Error(err))
			if !wait(ctx, delay) {
				return
			}
			delay = c.nextBackoff(delay)
		}
	}
}
