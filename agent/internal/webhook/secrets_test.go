package webhook

import (
	"context"
	"errors"
	"os"
	"reflect"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

var secretEnvs = []string{
	"KICK_CLIENT_ID", "KICK_CLIENT_SECRET", "TWITCH_EVENTSUB_SECRET",
	"ALCHEMY_SIGNING_KEY", "ALCHEMY_ETH_SIGNING_KEY",
}

func clearSecretEnvs(t *testing.T) {
	t.Helper()
	for _, name := range secretEnvs {
		// Setenv arranges to restore the original environment at cleanup.
		t.Setenv(name, "")
		if err := os.Unsetenv(name); err != nil {
			t.Fatal(err)
		}
	}
}

func TestLoadSecretsEnvironment(t *testing.T) {
	for _, name := range secretEnvs {
		t.Setenv(name, name)
	}
	want := Secrets{
		KickClientID: "KICK_CLIENT_ID", KickClientSecret: "KICK_CLIENT_SECRET",
		TwitchEventSubSecret: "TWITCH_EVENTSUB_SECRET", AlchemySigningKey: "ALCHEMY_SIGNING_KEY",
		AlchemyEthSigningKey: "ALCHEMY_ETH_SIGNING_KEY",
	}
	got := LoadSecrets(context.Background(), func(context.Context, string) (string, error) {
		t.Fatal("environment overrides must not fetch from Secret Manager")
		return "", nil
	})
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
	// A nil fetcher also skips client creation when every override is present.
	if got := LoadSecrets(context.Background(), nil); got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}

func TestLoadSecretsMissing(t *testing.T) {
	clearSecretEnvs(t)
	core, logs := observer.New(zap.WarnLevel)
	undo := zap.ReplaceGlobals(zap.New(core))
	defer undo()
	var names []string
	got := LoadSecrets(context.Background(), func(ctx context.Context, name string) (string, error) {
		names = append(names, name)
		return "", errors.New("secret not found")
	})
	if got != (Secrets{}) {
		t.Fatalf("missing secrets must remain empty: %+v", got)
	}
	want := []string{
		"projects/rtchat-47692/secrets/kick-client-id/versions/latest",
		"projects/rtchat-47692/secrets/kick-client-secret/versions/latest",
		"projects/rtchat-47692/secrets/twitch-eventsub-secret/versions/latest",
		"projects/rtchat-47692/secrets/alchemy-signing-key/versions/latest",
		"projects/rtchat-47692/secrets/alchemy-eth-signing-key/versions/latest",
	}
	if !reflect.DeepEqual(names, want) {
		t.Fatalf("got resource names %v, want %v", names, want)
	}
	if logs.Len() != len(want) {
		t.Fatalf("got %d warnings, want %d", logs.Len(), len(want))
	}
}

func TestLoadSecretsMixed(t *testing.T) {
	clearSecretEnvs(t)
	t.Setenv("KICK_CLIENT_ID", "override")
	t.Setenv("KICK_CLIENT_SECRET", "")
	got := LoadSecrets(context.Background(), func(ctx context.Context, name string) (string, error) {
		switch name {
		case "projects/rtchat-47692/secrets/twitch-eventsub-secret/versions/latest":
			return "eventsub", nil
		case "projects/rtchat-47692/secrets/alchemy-signing-key/versions/latest":
			return "discard on error", errors.New("permission denied")
		case "projects/rtchat-47692/secrets/alchemy-eth-signing-key/versions/latest":
			return "eth", nil
		default:
			t.Fatalf("unexpected fetch: %s", name)
			return "", nil
		}
	})
	want := Secrets{KickClientID: "override", TwitchEventSubSecret: "eventsub", AlchemyEthSigningKey: "eth"}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}
