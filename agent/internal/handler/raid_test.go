package handler

import (
	"context"
	"errors"
	"sync/atomic"
	"testing"
	"time"
)

type fakeRaidSocket struct {
	pings  int32
	closed int32
}

func (s *fakeRaidSocket) WriteJSON(v interface{}) error {
	if v.(map[string]interface{})["type"] == "PING" {
		atomic.AddInt32(&s.pings, 1)
	}
	return nil
}

func (s *fakeRaidSocket) ReadJSON(interface{}) error { return errors.New("fake EOF") }

func (s *fakeRaidSocket) Close() error { atomic.StoreInt32(&s.closed, 1); return nil }

func TestRaidSessionStopsWorkersOnReturn(t *testing.T) {
	h := testAgent()
	s := &fakeRaidSocket{}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	if err := h.bindRaidSession(ctx, s, "42", "uid", time.Millisecond); err == nil {
		t.Fatal("expected read error")
	}
	time.Sleep(20 * time.Millisecond)
	a := atomic.LoadInt32(&s.pings)
	time.Sleep(20 * time.Millisecond)
	if b := atomic.LoadInt32(&s.pings); b != a {
		t.Fatalf("ping worker still running after return: %d -> %d", a, b)
	}
	if atomic.LoadInt32(&s.closed) != 1 {
		t.Fatal("socket leaked")
	}
}

func TestRaidMalformedMessagesDoNotPanic(t *testing.T) {
	for _, m := range []map[string]interface{}{{"type": "RESPONSE"}, {"type": "RESPONSE", "error": 1}, {"type": "MESSAGE", "data": "bad"}, {"type": "MESSAGE", "data": map[string]interface{}{"topic": "raid.42", "message": 1}}, {"type": "MESSAGE", "data": map[string]interface{}{"topic": "raid.42", "message": `{"type":"raid_update_v2","raid":{"id":123}}`}}} {
		t.Run("malformed", func(t *testing.T) {
			defer func() {
				if r := recover(); r != nil {
					t.Fatalf("panic: %v", r)
				}
			}()
			_, _ = raidMessageDocument(m, "42", time.Now())
		})
	}
}

func TestRaidDocument(t *testing.T) {
	d, err := raidMessageDocument(map[string]interface{}{"type": "MESSAGE", "data": map[string]interface{}{"topic": "raid.42", "message": `{"type":"raid_update_v2","raid":{"id":"abc","viewer_count":10}}`}}, "42", time.Now())
	if err != nil || d == nil || d.channelID != "twitch:42" || d.messageID != "raid_update_v2-abc" || d.data["type"] != "raid_update_v2" {
		t.Fatalf("doc=%v err=%v", d, err)
	}
	_, err = raidMessageDocument(map[string]interface{}{"type": "RECONNECT"}, "42", time.Now())
	if !errors.Is(err, errReconnect) {
		t.Fatal(err)
	}
}

type serialSocket struct {
	writing int32
	overlap int32
}

func (s *serialSocket) WriteJSON(v interface{}) error {
	if v.(map[string]interface{})["type"] == "LISTEN" {
		atomic.StoreInt32(&s.writing, 1)
		time.Sleep(10 * time.Millisecond)
		atomic.StoreInt32(&s.writing, 0)
	} else if atomic.LoadInt32(&s.writing) != 0 {
		atomic.StoreInt32(&s.overlap, 1)
	}
	return nil
}

func (s *serialSocket) ReadJSON(interface{}) error { return errors.New("EOF") }

func (s *serialSocket) Close() error { return nil }

func TestRaidSerializesWrites(t *testing.T) {
	h := testAgent()
	s := &serialSocket{}
	_ = h.bindRaidSession(context.Background(), s, "42", "uid", time.Millisecond)
	if atomic.LoadInt32(&s.overlap) != 0 {
		t.Fatal("LISTEN and PING written concurrently; gorilla websocket permits one writer")
	}
}
