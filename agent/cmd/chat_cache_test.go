package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
)

func TestExplicitVideoDoesNotChangeDefaultChat(t *testing.T) {
	var chats []string
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/youtube/v3/videos":
			return respond(200, `{"items":[{"snippet":{"channelId":"`+own+`"},"liveStreamingDetails":{"activeLiveChatId":"alternate-chat"}}]}`), nil
		case "/youtube/v3/liveBroadcasts":
			return respond(200, `{"items":[{"snippet":{"channelId":"`+own+`","liveChatId":"default-chat"}}]}`), nil
		default:
			var body struct{ Snippet struct{ LiveChatID string } }
			data, _ := io.ReadAll(r.Body)
			_ = json.Unmarshal(data, &body)
			chats = append(chats, body.Snippet.LiveChatID)
			return respond(200, `{"id":"ok"}`), nil
		}
	})
	data := map[string]any{"provider": "youtube", "channelId": own, "message": "hi", "videoId": "dQw4w9WgXcQ"}
	code, body := call(t, s, "send", data, true)
	assertNull(t, code, body)
	delete(data, "videoId")
	code, body = call(t, s, "send", data, true)
	assertNull(t, code, body)
	if len(chats) != 2 || chats[0] != "alternate-chat" || chats[1] != "default-chat" {
		t.Fatalf("destinations %v: default request was contaminated by explicit-video cache", chats)
	}
}

type perUserProfileStore struct{ mockStore }

func (s *perUserProfileStore) Profile(ctx context.Context, uid string) (map[string]any, error) {
	id := other
	if uid == "channel-owner" {
		id = own
	}
	return map[string]any{"youtube": map[string]any{"id": id}}, nil
}
func TestChatDiscoveryCacheIsScopedToUser(t *testing.T) {
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/youtube/v3/liveBroadcasts":
			return respond(200, `{"items":[{"snippet":{"channelId":"`+own+`","liveChatId":"unlisted-chat"}}]}`), nil
		case "/channel/" + own + "/live":
			return respond(200, `<link rel="canonical" href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">`), nil
		case "/youtube/v3/videos":
			return respond(200, `{"items":[{"snippet":{"channelId":"`+own+`"},"liveStreamingDetails":{"activeLiveChatId":"public-chat"}}]}`), nil
		}
		t.Fatalf("unexpected request %s", r.URL)
		return nil, nil
	})
	s.store = &perUserProfileStore{}
	a, err := s.liveChat(context.Background(), "channel-owner", "owner-token", own, nil)
	if err != nil {
		t.Fatal(err)
	}
	b, err := s.liveChat(context.Background(), "viewer", "viewer-token", own, nil)
	if err != nil {
		t.Fatal(err)
	}
	if a != "unlisted-chat" || b != "public-chat" {
		t.Fatalf("owner=%s viewer=%s", a, b)
	}
}

func TestExplicitChatFailurePreservesDefaultCache(t *testing.T) {
	lookups := 0
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/youtube/v3/liveBroadcasts":
			lookups++
			return respond(200, `{"items":[{"snippet":{"liveChatId":"default-chat"}}]}`), nil
		case "/youtube/v3/videos":
			return respond(200, `{"items":[{"snippet":{"channelId":"`+own+`"},"liveStreamingDetails":{"activeLiveChatId":"explicit-chat"}}]}`), nil
		default:
			var body struct{ Snippet struct{ LiveChatID string } }
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			if body.Snippet.LiveChatID == "explicit-chat" {
				return respond(403, `{"error":{"errors":[{"reason":"liveChatEnded"}]}}`), nil
			}
			return respond(200, `{"id":"sent"}`), nil
		}
	})
	input := map[string]any{"provider": "youtube", "channelId": own, "message": "hi"}
	status, result := call(t, s, "send", input, true)
	assertNull(t, status, result)
	input["videoId"] = "dQw4w9WgXcQ"
	if status, _ := call(t, s, "send", input, true); status != 400 {
		t.Fatalf("ended explicit chat: %d", status)
	}
	delete(input, "videoId")
	status, result = call(t, s, "send", input, true)
	assertNull(t, status, result)
	if lookups != 1 {
		t.Fatal("explicit failure invalidated unrelated default cache")
	}
}
