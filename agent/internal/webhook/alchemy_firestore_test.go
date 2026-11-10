package webhook

import (
	"context"
	"encoding/json"
	"net"
	"sync"
	"testing"

	"cloud.google.com/go/firestore"
	"cloud.google.com/go/firestore/apiv1/firestorepb"
	"google.golang.org/api/option"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type atomicFirestoreServer struct {
	firestorepb.UnimplementedFirestoreServer
	mu        sync.Mutex
	documents map[string]*firestorepb.Document
	t         *testing.T
}

func (s *atomicFirestoreServer) Commit(ctx context.Context, req *firestorepb.CommitRequest) (*firestorepb.CommitResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(req.Writes) != 1 {
		s.t.Fatalf("unexpected writes: %v", req.Writes)
	}
	write := req.Writes[0]
	exists, ok := write.CurrentDocument.ConditionType.(*firestorepb.Precondition_Exists)
	if !ok || exists.Exists {
		s.t.Fatal("write is not atomic Create")
	}
	doc := write.GetUpdate()
	if _, exists := s.documents[doc.Name]; exists {
		return nil, status.Error(codes.AlreadyExists, "already exists")
	}
	s.documents[doc.Name] = doc
	now := timestamppb.Now()
	return &firestorepb.CommitResponse{CommitTime: now, WriteResults: []*firestorepb.WriteResult{{UpdateTime: now}}}, nil
}
func TestAlchemyFirestoreAtomicCreateAcrossClients(t *testing.T) {
	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	fake := &atomicFirestoreServer{documents: map[string]*firestorepb.Document{}, t: t}
	firestorepb.RegisterFirestoreServer(server, fake)
	go server.Serve(listener)
	defer server.Stop()
	ctx := context.Background()
	conn, err := grpc.NewClient("passthrough:///bufnet", grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) { return listener.Dial() }), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	clients := make([]*firestore.Client, 2)
	for i := range clients {
		clients[i], err = firestore.NewClient(ctx, "test-project", option.WithGRPCConn(conn), option.WithoutAuthentication())
		if err != nil {
			t.Fatal(err)
		}
		defer clients[i].Close()
	}
	var wg sync.WaitGroup
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			store := AlchemyFirestore{Client: clients[i%2]}
			if err := store.Create(ctx, "channels/twitch:123/messages", "stable-id", map[string]interface{}{"type": "realtimecash.donation", "activity": map[string]interface{}{"value": json.Number("9007199254740993"), "rawContract": map[string]interface{}{"rawValue": "0x20000000000001"}}}); err != nil {
				t.Error(err)
			}
		}(i)
	}
	wg.Wait()
	if len(fake.documents) != 1 {
		t.Fatalf("created %d documents", len(fake.documents))
	}
	for _, doc := range fake.documents {
		activity := doc.Fields["activity"].GetMapValue().Fields
		if activity["value"].GetDoubleValue() != 9007199254740992 {
			t.Fatal("numeric boundary changed")
		}
		if activity["rawContract"].GetMapValue().Fields["rawValue"].GetStringValue() != "0x20000000000001" {
			t.Fatal("exact token value lost")
		}
	}
}
