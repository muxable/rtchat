package webhook

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestLoadSecretsMissing(t *testing.T) {
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
		"projects/rtchat-47692/secrets/alchemy-matic-webhook-id/versions/latest",
		"projects/rtchat-47692/secrets/alchemy-eth-webhook-id/versions/latest",
	}
	if !reflect.DeepEqual(names, want) {
		t.Fatalf("got resource names %v, want %v", names, want)
	}
	if logs.Len() != len(want) {
		t.Fatalf("got %d warnings, want %d", logs.Len(), len(want))
	}
}

func TestLoadSecretsPartial(t *testing.T) {
	got := LoadSecrets(context.Background(), func(ctx context.Context, name string) (string, error) {
		switch name {
		case "projects/rtchat-47692/secrets/kick-client-id/versions/latest":
			return "kick", nil
		case "projects/rtchat-47692/secrets/twitch-eventsub-secret/versions/latest":
			return "eventsub", nil
		case "projects/rtchat-47692/secrets/alchemy-signing-key/versions/latest":
			return "discard on error", errors.New("permission denied")
		case "projects/rtchat-47692/secrets/alchemy-eth-signing-key/versions/latest":
			return "eth", nil
		default:
			return "", errors.New("secret not found")
		}
	})
	want := Secrets{KickClientID: "kick", TwitchEventSubSecret: "eventsub", AlchemyEthSigningKey: "eth"}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}
