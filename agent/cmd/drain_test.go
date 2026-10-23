package main

import (
	"net"
	"net/http"
	"testing"
	"time"
)

func TestDrainFinishesInFlightRequests(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	base := "http://" + listener.Addr().String()
	started := make(chan struct{})
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("/slow", func(w http.ResponseWriter, r *http.Request) {
		close(started)
		time.Sleep(300 * time.Millisecond)
		w.Write([]byte("done"))
	})
	d := newDrainableServer("")
	served := make(chan error, 1)
	go func() { served <- d.serve(listener, mux) }()

	if res, err := http.Get(base + "/healthz"); err != nil || res.StatusCode != 200 {
		t.Fatal("healthy before drain", res, err)
	}
	slow := make(chan int, 1)
	go func() {
		res, err := http.Get(base + "/slow")
		if err != nil {
			slow <- 0
			return
		}
		slow <- res.StatusCode
	}()
	<-started
	drained := make(chan struct{})
	go func() { d.Drain(200*time.Millisecond, 2*time.Second); close(drained) }()

	time.Sleep(50 * time.Millisecond)
	client := &http.Client{Transport: &http.Transport{DisableKeepAlives: true}}
	res, err := client.Get(base + "/healthz")
	if err != nil || res.StatusCode != http.StatusServiceUnavailable {
		t.Fatal("health check should fail while draining", res, err)
	}
	if code := <-slow; code != 200 {
		t.Fatal("in-flight request dropped", code)
	}
	<-drained
	if err := <-served; err != nil {
		t.Fatal(err)
	}
	if _, err := client.Get(base + "/healthz"); err == nil {
		t.Fatal("server still accepting after drain")
	}
}
