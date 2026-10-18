package twitch

import (
	"context"
	"crypto/tls"
	"errors"
	"golang.org/x/net/websocket"
	"net"
	"strings"
	"time"
)

// Keep the legacy fallback until clients capable of prompting for reauthorization
// have rolled out (#1479). A successful write cannot guarantee IRC acceptance.
func SendIRC(ctx context.Context, token, login, channel, message string) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	dialer := tls.Dialer{NetDialer: &net.Dialer{Timeout: 10 * time.Second}}
	conn, err := dialer.DialContext(ctx, "tcp", "irc-ws.chat.twitch.tv:443")
	if err != nil {
		return errors.New("IRC connection failed")
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		conn.SetDeadline(deadline)
	}
	config, err := websocket.NewConfig("wss://irc-ws.chat.twitch.tv:443", "https://chat.rtirl.com")
	if err != nil {
		return err
	}
	ws, err := websocket.NewClient(config, conn)
	if err != nil {
		return errors.New("IRC handshake failed")
	}
	defer ws.Close()
	// The fallback must not turn a multiline message into extra IRC commands.
	message = strings.NewReplacer("\r", " ", "\n", " ").Replace(message)
	for _, line := range []string{"CAP REQ :twitch.tv/commands", "PASS oauth:" + token, "NICK " + login, "PRIVMSG #" + channel + " :" + message} {
		if err := websocket.Message.Send(ws, line); err != nil {
			return errors.New("IRC send failed")
		}
	}
	return nil
}
