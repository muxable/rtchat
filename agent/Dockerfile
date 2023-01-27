FROM golang:1.19-alpine AS builder

WORKDIR /go/src/app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . .

RUN go build -o /go/bin/app cmd/main.go

EXPOSE 8080

ENTRYPOINT ["/go/bin/app"]