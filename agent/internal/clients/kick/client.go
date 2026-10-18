// Package kick implements Kick API authentication and transport.
package kick

import (
	"net/http"

	"github.com/muxable/rtchat/agent/internal/clients"
)

type Client struct{ clients.Client }

func New(httpClient *http.Client, token string) *Client {
	return &Client{clients.Client{
		HTTP: httpClient, BaseURL: "https://api.kick.com/public/v1",
		Headers: http.Header{"Authorization": {"Bearer " + token}},
	}}
}
