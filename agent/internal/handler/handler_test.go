package handler

import (
	"errors"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
	"google.golang.org/api/iterator"
	"io"
	"reflect"
	"testing"

	"github.com/muxable/rtchat/agent/internal/agent"
)

type fakeCloser struct{}

func (*fakeCloser) Close() error { return nil }

func TestNewClientFallbacks(t *testing.T) {
	for _, tc := range []struct {
		name        string
		lookupFails bool
		success     int
		wantCalls   []string
	}{
		{"owner", false, 1, []string{"owner"}}, {"bot", false, 2, []string{"owner", "JSdHKOEgwcZijVsuXXdftmizt6E3"}}, {"anonymous", false, 3, []string{"owner", "JSdHKOEgwcZijVsuXXdftmizt6E3", "anonymous"}}, {"lookup failure", true, 1, []string{"JSdHKOEgwcZijVsuXXdftmizt6E3"}}, {"all fail", false, 0, []string{"owner", "JSdHKOEgwcZijVsuXXdftmizt6E3", "anonymous"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			calls := []string{}
			sentinel := &fakeCloser{}
			attempt := func(id string) (io.Closer, error) {
				calls = append(calls, id)
				if len(calls) == tc.success {
					return sentinel, nil
				}
				return nil, errors.New("fake join failed")
			}
			got, err := newClientWithFallbacks(testRequest(), func(channel string) (string, error) {
				if channel != "room" {
					t.Fatal(channel)
				}
				if tc.lookupFails {
					return "", errors.New("not found")
				}
				return "owner", nil
			}, func(_ *agent.Request, id string) (io.Closer, error) { return attempt(id) }, func(*agent.Request) (io.Closer, error) { return attempt("anonymous") })
			if !reflect.DeepEqual(calls, tc.wantCalls) {
				t.Fatal(calls)
			}
			if tc.success == 0 {
				if got != nil || err == nil {
					t.Fatalf("client=%v err=%v", got, err)
				}
			} else if got != sentinel || err != nil {
				t.Fatalf("client=%v err=%v", got, err)
			}
		})
	}
}

func TestProfileLookupFailureSeverity(t *testing.T) {
	for _, lookupErr := range []error{iterator.Done, errors.New("Firestore unavailable")} {
		core, logs := observer.New(zap.InfoLevel)
		undo := zap.ReplaceGlobals(zap.New(core))
		_, err := newClientWithFallbacks(testRequest(), func(string) (string, error) { return "", lookupErr }, func(*agent.Request, string) (io.Closer, error) { return &fakeCloser{}, nil }, nil)
		undo()
		if err != nil {
			t.Fatal(err)
		}
		entries := logs.All()
		want := zap.WarnLevel
		if errors.Is(lookupErr, iterator.Done) {
			want = zap.InfoLevel
		}
		if len(entries) != 1 || entries[0].Level != want {
			t.Fatal(entries)
		}
	}
}
