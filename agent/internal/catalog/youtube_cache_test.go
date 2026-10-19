package catalog

import (
	"context"
	"errors"
	"net/http"
	"testing"
)

func TestYouTubeRecoversAfterTransientFailure(t *testing.T) {
	s, store, _ := fixture()
	requests := 0
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
		requests++
		if requests == 1 {
			return response(503, `{}`), nil
		}
		return response(200, `{"items":[{"id":"UCabcdefghijklmnopqr12_-","snippet":{"title":"Creator"}}]}`), nil
	})}
	s.searchYouTube(context.Background(), "creator")
	got := s.searchYouTube(context.Background(), "creator")
	if len(got) != 1 {
		t.Fatalf("channel stayed hidden after transient 503: requests=%d cacheWrites=%d result=%v", requests, store.cacheWrites, got)
	}
}

func TestYouTubeDoesNotCacheInvalidResponses(t *testing.T) {
	for _, payload := range []string{`invalid`, `null`, `{}`, `{"items":null}`, `{"items":{}}`, `{"items":[{}]}`} {
		t.Run(payload, func(t *testing.T) {
			s, store, _ := fixture()
			s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return response(200, payload), nil })}
			s.searchYouTube(context.Background(), "creator")
			if store.cacheWrites != 0 {
				t.Fatalf("invalid response cached: payload=%s writes=%d", payload, store.cacheWrites)
			}
		})
	}
}

func TestYouTubeCachedResultSurvivesCredentialLookupFailure(t *testing.T) {
	s, store, _ := fixture()
	store.cached["@creator"] = []map[string]any{{"provider": "youtube", "channelId": "UCabcdefghijklmnopqr12_-"}}
	s.YouTubeAPIKey = func(context.Context) (string, error) { return "", errors.New("temporary credentials outage") }
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
		t.Fatal("cached lookup reached provider")
		return nil, nil
	})}
	if result := s.searchYouTube(context.Background(), "creator"); len(result) != 1 {
		t.Fatal("cached result unavailable during credential outage")
	}
}
