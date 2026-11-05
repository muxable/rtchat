# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.27-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

ARG TARGETOS
ARG TARGETARCH
ARG VCS_REF=development
# a static binary, so it runs on distroless. time zones are embedded with
# time/tzdata; TLS roots come from the base image.
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w -X github.com/muxable/rtchat/agent/internal/observability.Version=${VCS_REF}" -o /out/app ./cmd

# ca-certificates, tzdata and a nonroot user, nothing else.
FROM gcr.io/distroless/static-debian13:nonroot

COPY --from=builder /out/app /go/bin/app

EXPOSE 8080

ENTRYPOINT ["/go/bin/app", "--supervise"]
