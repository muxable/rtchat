package agent

import (
	"strings"

	"cloud.google.com/go/firestore"
)

type Provider string

const (
	ProviderTwitch Provider = "twitch"
)

type Request firestore.DocumentRef

func (r *Request) Provider() Provider {
	i := strings.Index(r.ID, ":")
	if i < 0 {
		return ""
	}
	return Provider(r.ID[:i])
}

func (r *Request) Channel() string {
	i := strings.Index(r.ID, ":")
	if i < 0 {
		return ""
	}
	return r.ID[i+1:]
}

func (r *Request) String() string {
	return r.ID
}
