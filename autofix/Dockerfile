# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.27-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY *.go ./

ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/autofix .

# git applies and pushes patches; nothing else is needed.
FROM alpine:3.22

RUN apk add --no-cache git ca-certificates && adduser -D -u 65532 nonroot

COPY --from=builder /out/autofix /usr/local/bin/autofix

USER nonroot

ENTRYPOINT ["/usr/local/bin/autofix"]
