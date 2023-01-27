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
	return Provider(r.ID[:strings.Index(r.ID, ":")])
}

func (r *Request) Channel() string {
	return r.ID[strings.Index(r.ID, ":")+1:]
}

func (r *Request) String() string {
	return r.ID
}
