package agent

import (
	"testing"

	"cloud.google.com/go/firestore"
)

func TestRequestParsing(t *testing.T) {
	for _, tc := range []struct {
		id       string
		provider Provider
		channel  string
	}{
		{"twitch:room", ProviderTwitch, "room"}, {"other:a:b", "other", "a:b"}, {"twitch:", ProviderTwitch, ""}, {"", "", ""}, {"malformed", "", ""},
	} {
		t.Run(tc.id, func(t *testing.T) {
			r := (*Request)(&firestore.DocumentRef{ID: tc.id})
			if r.Provider() != tc.provider || r.Channel() != tc.channel || r.String() != tc.id {
				t.Fatalf("unexpected parse: %q %q %q", r.Provider(), r.Channel(), r.String())
			}
		})
	}
}
