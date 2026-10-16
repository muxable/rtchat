package eventsubmigration

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

type Snapshot struct {
	Schema          int            `json:"schema"`
	CreatedAt       time.Time      `json:"createdAt"`
	ClientID        string         `json:"clientId"`
	LegacyCallbacks [2]string      `json:"legacyCallbacks"`
	TargetCallback  string         `json:"targetCallback"`
	TotalCost       int            `json:"totalCost"`
	MaxTotalCost    int            `json:"maxTotalCost"`
	Subscriptions   []Subscription `json:"subscriptions"`
}
type Progress struct {
	TargetID   string `json:"targetId"`
	Created    bool   `json:"created"`
	DeletedOld bool   `json:"deletedOld"`
	RolledBack bool   `json:"rolledBack"`
}
type Checkpoint struct {
	SnapshotHash string              `json:"snapshotHash"`
	Entries      map[string]Progress `json:"entries"`
}

func (s Snapshot) hash() string {
	data, _ := json.Marshal(s)
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}
func (s Snapshot) Validate(clientID string) error {
	if s.Schema != 1 || s.ClientID != clientID || s.LegacyCallbacks != [2]string{LegacyCallback, AliasCallback} || s.TargetCallback != TargetCallback {
		return fmt.Errorf("snapshot identity, schema, or callback allowlist does not match")
	}
	ids := map[string]bool{}
	for _, sub := range s.Subscriptions {
		if sub.ID == "" || ids[sub.ID] || sub.Type == "" || sub.Version == "" {
			return fmt.Errorf("invalid or duplicate snapshot subscription")
		}
		ids[sub.ID] = true
		var condition map[string]interface{}
		if err := json.Unmarshal(sub.Condition, &condition); err != nil || condition == nil {
			return fmt.Errorf("invalid subscription condition")
		}
	}
	return nil
}
func WriteSnapshot(path string, snapshot Snapshot) error {
	data, err := json.MarshalIndent(snapshot, "", "  ")
	if err != nil {
		return err
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return err
	}
	if _, err = file.Write(append(data, '\n')); err != nil {
		file.Close()
		return err
	}
	if err = file.Sync(); err != nil {
		file.Close()
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	return syncDirectory(filepath.Dir(path))
}
func ReadSnapshot(path string) (Snapshot, error) {
	var snapshot Snapshot
	data, err := os.ReadFile(path)
	if err != nil {
		return snapshot, err
	}
	err = json.Unmarshal(data, &snapshot)
	return snapshot, err
}
func ReadCheckpoint(path string, snapshot Snapshot) (Checkpoint, error) {
	checkpoint := Checkpoint{SnapshotHash: snapshot.hash(), Entries: map[string]Progress{}}
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return checkpoint, nil
	}
	if err != nil {
		return checkpoint, err
	}
	if err = json.Unmarshal(data, &checkpoint); err != nil {
		return checkpoint, err
	}
	if checkpoint.SnapshotHash != snapshot.hash() || checkpoint.Entries == nil {
		return checkpoint, fmt.Errorf("checkpoint does not belong to this snapshot")
	}
	return checkpoint, nil
}
func WriteCheckpoint(path string, checkpoint Checkpoint) error {
	data, err := json.MarshalIndent(checkpoint, "", "  ")
	if err != nil {
		return err
	}
	dir := filepath.Dir(path)
	file, err := os.CreateTemp(dir, ".eventsub-state-*")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	if err = file.Chmod(0600); err == nil {
		_, err = file.Write(append(data, '\n'))
	}
	if err == nil {
		err = file.Sync()
	}
	closeErr := file.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	if err = os.Rename(file.Name(), path); err != nil {
		return err
	}
	return syncDirectory(dir)
}
func syncDirectory(dir string) error {
	directory, err := os.Open(dir)
	if err != nil {
		return err
	}
	defer directory.Close()
	return directory.Sync()
}
