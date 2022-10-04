# syntax=docker/dockerfile:1

FROM golang:1.19-alpine AS builder

WORKDIR /go/src/app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . .

RUN go build -o /go/bin/app cmd/main.go

FROM alpine

COPY --from=builder /go/bin/app /go/bin/app

ENTRYPOINT ["/go/bin/app"]