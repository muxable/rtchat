// Package youtube implements YouTube Data API authentication and transport.
package youtube

import (
	"net/http"

	"github.com/muxable/rtchat/agent/internal/clients"
)

type Client struct{ clients.Client }

// API-key requests pass key in the query and leave token empty.
func New(httpClient *http.Client, token string) *Client {
	headers := make(http.Header)
	if token != "" {
		headers.Set("Authorization", "Bearer "+token)
	}
	return &Client{clients.Client{HTTP: httpClient, BaseURL: "https://www.googleapis.com/youtube/v3", Headers: headers}}
}
