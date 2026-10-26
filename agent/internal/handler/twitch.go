package handler

import (
	"context"
	"errors"
	"fmt"
	"io"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v4"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/chatmetrics"
	"go.uber.org/zap"
	"golang.org/x/oauth2"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type TwitchAgent struct {
	Firestore              *firestore.Client
	ClientID, ClientSecret string
	// WaitForAuth gates initial IRC logins across replicas, outside the handshake timeout.
	WaitForAuth func(context.Context, string) error
	Context     context.Context
	// Optional dependencies allow lifecycle tests without external services.
	loadProfile func(string) (map[string]interface{}, error)
	tokenSource func(string) (oauth2.TokenSource, error)
	newChat     func(string, string) chatConnection
	bindChat    func(chatConnection)
}

type chatConnection interface {
	OnConnect(func())
	Join(...string)
	Connect() error
	Disconnect() error
	OnReconnectMessage(func(twitch.ReconnectMessage))
	SetIRCToken(string)
}

func joinWithTimeout(client chatConnection, channel string, timeout time.Duration) error {
	// connect to the chat
	success := make(chan struct{})
	abandoned := make(chan struct{})
	once := &sync.Once{}
	client.OnConnect(func() {
		select {
		case <-abandoned:
			_ = client.Disconnect()
			return
		default:
		}
		// apparently this can be called multiple times
		once.Do(func() {
			close(success)
		})
	})
	client.Join(channel)

	finished := make(chan error, 1)
	go func() {
		err := client.Connect()
		finished <- err
		if err != nil {
			if !errors.Is(err, twitch.ErrClientDisconnected) {
				zap.L().Error("failed to connect to chat", zap.Error(err))
			}
		}
	}()

	// wait for success signal or timeout
	select {
	case <-success:
		return nil
	case err := <-finished:
		if err == nil {
			return errors.New("connection ended before joining")
		}
		return err
	case <-time.After(timeout):
		close(abandoned)
		if err := client.Disconnect(); err != nil {
			if !errors.Is(err, twitch.ErrConnectionIsNotOpen) {
				zap.L().Error("failed to disconnect from chat", zap.Error(err))
			}
		}
		return errors.New("timeout")
	}
}

func (h *TwitchAgent) write(channelID, messageID string, data interface{}) chatmetrics.Outcome {
	duplicate := false
	if err := createMessage(context.Background(), func(ctx context.Context) error {
		_, err := h.Firestore.Collection("channels").Doc(channelID).Collection("messages").Doc(messageID).Create(ctx, data)
		duplicate = status.Code(err) == codes.AlreadyExists
		return err
	}); err != nil {
		zap.L().Error("failed to write message to firestore", zap.Error(err), zap.String("channelId", channelID), zap.String("messageId", messageID))
		return chatmetrics.Failed
	}
	if duplicate {
		return chatmetrics.Duplicate
	}
	return chatmetrics.Created
}

func (h *TwitchAgent) bindEvents(client *twitch.Client) {
	client.OnUserNoticeMessage(func(message twitch.UserNoticeMessage) {
		go h.writeDocument("usernotice", userNoticeDocument(message, time.Now()))
	})

	// configure handlers
	client.OnClearChatMessage(func(message twitch.ClearChatMessage) {
		go h.writeDocument("clearchat", clearChatDocument(message, time.Now()))
	})

	client.OnClearMessage(func(message twitch.ClearMessage) {
		userID, err := auth.TwitchUserIDFromUsername(h.Firestore, h.ClientID, h.ClientSecret, message.Channel)
		if err != nil {
			zap.L().Error("failed to get twitch user id", zap.Error(err))
			chatmetrics.Record("twitch", "clearmsg", chatmetrics.Failed)
			return
		}
		go h.writeDocument("clearmsg", clearMessageDocument(message, userID, time.Now()))
	})

	client.OnPrivateMessage(func(message twitch.PrivateMessage) {
		go h.writeDocument("message", privateMessageDocument(message, time.Now()))
	})
}

type AuthenticatedTwitchClient struct {
	client chatConnection
}

func (c *AuthenticatedTwitchClient) Close() error {
	if c.client == nil {
		return nil
	}
	return c.client.Disconnect()
}

type AnonymousTwitchClient struct {
	client chatConnection
}

func (c *AnonymousTwitchClient) Close() error {
	return c.client.Disconnect()
}

func (h *TwitchAgent) JoinAsUser(r *agent.Request, asUserID string) (io.Closer, error) {
	zap.L().Info("joining as user", zap.String("asUserID", asUserID), zap.String("request", r.String()))
	profileData, err := h.profile(asUserID)
	if err != nil {
		return nil, err
	}
	login, ok := profileData["login"].(string)
	if !ok || login == "" {
		return nil, errors.New("invalid twitch login")
	}
	if login != "realtimechat" {
		id, ok := profileData["id"].(string)
		if !ok || id == "" {
			return nil, errors.New("invalid twitch id")
		}
	}
	authProvider, err := h.tokens(asUserID)
	if err != nil {
		return nil, err
	}

	token, err := authProvider.Token()
	if err != nil {
		return nil, err
	}

	if h.WaitForAuth != nil {
		ctx := h.Context
		if ctx == nil {
			ctx = context.Background()
		}
		bounded, cancel := context.WithTimeout(ctx, 2*time.Minute)
		err := h.WaitForAuth(bounded, login)
		cancel()
		if err != nil {
			return nil, fmt.Errorf("wait for IRC authentication slot: %w", err)
		}
		// The token may expire while waiting behind other channels during a rollout.
		if !token.Valid() {
			token, err = authProvider.Token()
			if err != nil {
				return nil, err
			}
		}
	}
	// create a new chat client and attempt to connect
	client := h.chat(login, fmt.Sprintf("oauth:%s", token.AccessToken))

	h.bind(client)
	installReconnect(client, authProvider)
	if err := joinWithTimeout(client, r.Channel(), 5*time.Second); err != nil {
		return nil, err
	}

	if login != "realtimechat" {
		return &AuthenticatedTwitchClient{client: client}, nil
	}
	return &AnonymousTwitchClient{client: client}, nil
}

func (h *TwitchAgent) JoinAnonymously(r *agent.Request) (*AnonymousTwitchClient, error) {
	// create a new chat client and attempt to connect
	client := h.chat("", "")

	// join the channel
	h.bind(client)
	return &AnonymousTwitchClient{client: client}, joinWithTimeout(client, r.Channel(), 5*time.Second)
}

// writeDocument counts every received event by kind; events without a
// document (e.g. non-announcement user notices) count as skipped.
func (h *TwitchAgent) writeDocument(kind string, doc *chatDocument) {
	outcome := chatmetrics.Skipped
	if doc != nil {
		outcome = h.write(doc.channelID, doc.messageID, doc.data)
	}
	chatmetrics.Record("twitch", kind, outcome)
}

func (h *TwitchAgent) profile(userID string) (map[string]interface{}, error) {
	if h.loadProfile != nil {
		return h.loadProfile(userID)
	}
	doc, err := h.Firestore.Collection("profiles").Doc(userID).Get(context.Background())
	if err != nil {
		return nil, err
	}
	return twitchProfile(doc.Data())
}

func (h *TwitchAgent) tokens(userID string) (oauth2.TokenSource, error) {
	if h.tokenSource != nil {
		return h.tokenSource(userID)
	}
	return auth.NewFirestoreTwitchTokenSource(h.Firestore, h.ClientID, h.ClientSecret, userID)
}

func (h *TwitchAgent) chat(login, token string) chatConnection {
	if h.newChat != nil {
		return h.newChat(login, token)
	}
	if login == "" {
		return twitch.NewAnonymousClient()
	}
	return twitch.NewClient(login, token)
}

func (h *TwitchAgent) bind(client chatConnection) {
	if h.bindChat != nil {
		h.bindChat(client)
		return
	}
	h.bindEvents(client.(*twitch.Client))
}

// go-twitch-irc invokes this callback before its own reconnect loop continues.
func installReconnect(client chatConnection, source oauth2.TokenSource) {
	client.OnReconnectMessage(func(twitch.ReconnectMessage) {
		token, err := source.Token()
		if err != nil {
			zap.L().Error("failed to refresh token", zap.Error(err))
			return
		}
		client.SetIRCToken("oauth:" + token.AccessToken)
	})
}

func createMessage(ctx context.Context, create func(context.Context) error) error {
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	for attempt := 0; ; attempt++ {
		err := create(ctx)
		if err == nil || status.Code(err) == codes.AlreadyExists {
			return nil
		}
		switch status.Code(err) {
		case codes.Unavailable, codes.DeadlineExceeded, codes.Aborted, codes.ResourceExhausted:
		default:
			return err
		}
		if attempt == 2 {
			return err
		}
		timer := time.NewTimer(time.Duration(attempt+1) * 100 * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
}

func twitchProfile(data map[string]interface{}) (map[string]interface{}, error) {
	profile, ok := data["twitch"].(map[string]interface{})
	if !ok {
		return nil, errors.New("invalid twitch profile")
	}
	return profile, nil
}
