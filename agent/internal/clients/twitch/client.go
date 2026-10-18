// Package twitch implements Twitch API authentication and transport.
package twitch

import (
	"context"
	"net/http"

	"github.com/muxable/rtchat/agent/internal/clients"
)

type Client struct{ clients.Client }

func New(httpClient *http.Client, clientID, token string) *Client {
	return &Client{clients.Client{
		HTTP: httpClient, BaseURL: "https://api.twitch.tv/helix",
		Headers: http.Header{"Authorization": {"Bearer " + token}, "Client-Id": {clientID}},
	}}
}

func (c *Client) Validate(ctx context.Context, token string, out any) error {
	validation := clients.Client{
		HTTP: c.HTTP, BaseURL: "https://id.twitch.tv/oauth2",
		Headers: http.Header{"Authorization": {"OAuth " + token}},
	}
	return validation.Get(ctx, "/validate", out)
}
