package twitch

import (
	"bufio"
	"context"
	"fmt"
	"net"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestIRCEmoteStateAndCancellation(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	serverDone := make(chan struct{})
	go func() {
		defer close(serverDone)
		reader := bufio.NewReader(server)
		for _, prefix := range []string{"CAP REQ :twitch.tv/tags twitch.tv/commands", "PASS oauth:user-token", "NICK streamer"} {
			line, err := reader.ReadString('\n')
			if err != nil || strings.TrimSpace(line) != prefix {
				t.Error("incorrect IRC login sequence")
				return
			}
		}
		fmt.Fprint(server, "PING :tmi.twitch.tv\r\n")
		line, err := reader.ReadString('\n')
		if err != nil || strings.TrimSpace(line) != "PONG :tmi.twitch.tv" {
			t.Error("PING not answered")
			return
		}
		fmt.Fprint(server, "@emote-sets=0,11,22;user-id=123 :tmi.twitch.tv GLOBALUSERSTATE\r\n")
	}()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	sets, err := readEmoteSets(ctx, client, "user-token", "streamer")
	if err != nil || !reflect.DeepEqual(sets, []string{"0", "11", "22"}) {
		t.Fatalf("IRC state %v %v", sets, err)
	}
	<-serverDone
	client2, server2 := net.Pipe()
	defer client2.Close()
	defer server2.Close()
	ctx2, cancel2 := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { defer close(done); readEmoteSets(ctx2, client2, "token", "login") }()
	cancel2()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("IRC cancellation leaked connection")
	}
	if _, err := readEmoteSets(context.Background(), client, "injected\r\nJOIN #channel", "login"); err == nil {
		t.Fatal("IRC command injection accepted")
	}
}
