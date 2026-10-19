package twitch

import (
	"bufio"
	"context"
	"crypto/tls"
	"errors"
	"fmt"
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

// EmoteSets opens one short-lived TLS connection and always closes it. No
// channels are joined, and cancellation interrupts reads without leaking a client.
func EmoteSets(ctx context.Context, token, login string) ([]string, error) {
	ctx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	dialer := tls.Dialer{NetDialer: &net.Dialer{Timeout: 5 * time.Second}, Config: &tls.Config{MinVersion: tls.VersionTLS12}}
	conn, err := dialer.DialContext(ctx, "tcp", "irc.chat.twitch.tv:6697")
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	return readEmoteSets(ctx, conn, token, login)
}
func readEmoteSets(ctx context.Context, conn net.Conn, token, login string) ([]string, error) {
	if strings.ContainsAny(token+login, "\r\n") {
		return nil, errors.New("invalid IRC credentials")
	}
	deadline, ok := ctx.Deadline()
	if !ok {
		deadline = time.Now().Add(8 * time.Second)
	}
	conn.SetDeadline(deadline)
	done := make(chan struct{})
	defer close(done)
	go func() {
		select {
		case <-ctx.Done():
			conn.Close()
		case <-done:
		}
	}()
	if _, err := fmt.Fprintf(conn, "CAP REQ :twitch.tv/tags twitch.tv/commands\r\nPASS oauth:%s\r\nNICK %s\r\n", token, login); err != nil {
		return nil, err
	}
	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "PING ") {
			fmt.Fprintf(conn, "PONG %s\r\n", strings.TrimPrefix(line, "PING "))
			continue
		}
		if !strings.Contains(line, " GLOBALUSERSTATE") || !strings.HasPrefix(line, "@") {
			continue
		}
		tagPart := strings.SplitN(line[1:], " ", 2)[0]
		for _, tag := range strings.Split(tagPart, ";") {
			if strings.HasPrefix(tag, "emote-sets=") {
				value := strings.TrimPrefix(tag, "emote-sets=")
				if value == "" {
					return []string{}, nil
				}
				return strings.Split(value, ","), nil
			}
		}
		return []string{}, nil
	}
	return nil, errors.New("IRC emote state unavailable")
}
