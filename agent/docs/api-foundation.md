# Managed callable API foundation

`internal/callable` implements the Firebase callable wire protocol documented at
https://firebase.google.com/docs/functions/callable-reference. It exposes individual
function names at `https://rtchat-api.rtirl.com/<name>`; Firebase clients should use
custom callable URLs so the SDK continues attaching Firebase ID tokens.

Register real migrated handlers before mounting onto the existing HTTP mux:

```go
verify, err := callable.FirebaseVerifier(ctx, "rtchat-47692")
// Handle initialization failure; nil verification rejects supplied/protected credentials.
api := callable.NewServer(verify)
providers := provider.NewService(db, nil)
api.Register("send", true, func(ctx context.Context, data json.RawMessage) (any, error) {
    uid := callable.UID(ctx) // populated only by verified Firebase ID tokens
    _ = uid
    _ = providers
    // Decode/validate handler data, perform operation, return nil for null success.
    return nil, nil
})
api.Mount(existingMux)
```

The example illustrates registration; the foundation itself installs no placeholder
function endpoints. Authentication initialization errors do not stop webhook/chat
startup. Registering public handlers with `false` permits absent credentials but
still rejects invalid supplied tokens. Protected handlers reject absent tokens.
Handlers use `*callable.Error{Code: "invalid-argument", Message: "...", Details: ...}`
for expected errors. Unexpected errors are hidden behind INTERNAL. Canonical
Firebase error codes are hyphenated in Go and uppercase with underscores on the wire.
Responses always include `result`, including null. Request data must be an exact
single-member JSON envelope; body limit is 1 MiB, handler timeout is 60 seconds.
CORS preflight permits Firebase SDK headers without cookie credentials.

The existing functions source has no `enforceAppCheck` setting. If a deployment has
separately enabled enforcement, preserve it by configuring
the result of `callable.FirebaseAppCheckVerifier(...)` with
`api.SetAppCheckVerifier(verify)` (handle initialization errors)
and registering those routes with
`RegisterWithOptions(name, callable.Options{RequireAuth: true, RequireAppCheck: true}, handler)`.
Enforced routes fail closed if verification is missing or invalid. App Check is
never inferred from an unverified client header. ID verification uses Firebase
Admin SDK signature/issuer/audience/expiry verification, without revocation lookups,
matching the existing callable default.

`internal/provider.Service` exposes:

```go
Credentials(ctx, provider string) (provider.Credentials, error) // ClientID, ClientSecret
AccessToken(ctx, uid, provider string) (string, error)
AppAccessToken(ctx, provider string) (string, error) // Twitch and Kick only
```

`provider.ErrNoToken` means no usable grant or a revoked grant; handlers decide how
to map this to a callable error. Other failures must not be treated as a user signout.
Unknown providers fail before any credential or token lookup.

Provider credentials load lazily from Secret Manager in project `rtchat-47692`.
Twitch uses the existing public client ID and `twitch-client-secret`. Kick,
Streamlabs, and StreamElements use `<provider>-client-id` and
`<provider>-client-secret`. YouTube uses `youtube-oauth-client-id` and
`youtube-oauth-client-secret`. The existing runtime config must be migrated to these
secrets and the MIG identity granted access before enabling each provider. In the
current inventory Streamlabs secrets are absent and must be provisioned. Missing
optional credentials never affect unrelated chat/webhook startup. Successful
credential reads are cached for the lifetime of the service; rotate by restarting
instances. Network operations have bounded contexts and never log token payloads.

Tokens remain JSON strings in `tokens/{uid}[provider]`, with `access_token`,
`refresh_token`, ISO `expires_at`, and preserved provider-specific fields such as
scope. Refreshes preserve a previous refresh token when Google omits it and save
rotated refresh tokens. Grants without expiry remain usable. Expiring grants refresh
with a five-minute safety margin. Invalid grants remove only the affected provider
from the tokens and profile document; temporary failures preserve the grant.

Each refresh claims a 20-second Firestore transaction lease in the sibling field
`_refresh_<provider>`, performs its bounded HTTP call outside the transaction, then
persists only if both the lease owner and serialized old token still match. OAuth
callbacks that write a newer grant win. Other MIG processes wait and re-read;
process crashes release the lease by expiry. This coordinates only consumers using
this service: legacy Cloud Functions and the existing IRC Twitch token source do
not participate in these leases. Do not run competing legacy refreshers for the
same rotating provider grants during cutover. The `NewServiceWithStore` interface
supports deterministic injected transport/storage tests.

Verification: `cd agent && go test ./...` and
`go test -race ./internal/callable ./internal/provider`. Unit tests cover shared
refresh concurrency and compare-and-swap semantics using a store implementation;
real Firestore transaction/IAM and provider grants still need staging smoke tests.
No production callbacks or existing functions are changed by this foundation.
