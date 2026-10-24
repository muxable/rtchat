package eventsubmigration

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// The checkpoint for ~180,000 subscriptions is tens of megabytes, and each
// subscription updates it several times. Rewriting it on every update would
// dominate the run, so updates are appended to a journal (one fsynced JSON
// line each) and folded into the state file when a run starts.

type journalLine struct {
	SnapshotHash string    `json:"snapshotHash,omitempty"`
	ID           string    `json:"id,omitempty"`
	Progress     *Progress `json:"progress,omitempty"`
}

// LoadCheckpoint reads the compacted state file and replays the journal.
func LoadCheckpoint(statePath, journalPath string, snapshot Snapshot) (Checkpoint, error) {
	checkpoint, err := ReadCheckpoint(statePath, snapshot)
	if err != nil {
		return checkpoint, err
	}
	file, err := os.Open(journalPath)
	if os.IsNotExist(err) {
		return checkpoint, nil
	}
	if err != nil {
		return checkpoint, err
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 64<<10), 1<<20)
	var pending error
	for first := true; scanner.Scan(); first = false {
		if pending != nil {
			return checkpoint, pending
		}
		var line journalLine
		if err := json.Unmarshal(scanner.Bytes(), &line); err != nil {
			// Only a torn final line (a crash mid-append, never acknowledged
			// to the migrator) may be ignored.
			pending = fmt.Errorf("checkpoint journal is corrupt")
			continue
		}
		if first {
			if line.SnapshotHash != checkpoint.SnapshotHash {
				return checkpoint, fmt.Errorf("checkpoint journal does not belong to this snapshot")
			}
			continue
		}
		if line.ID == "" || line.Progress == nil {
			return checkpoint, fmt.Errorf("checkpoint journal is corrupt")
		}
		checkpoint.Entries[line.ID] = *line.Progress
	}
	return checkpoint, scanner.Err()
}

// CompactCheckpoint folds the journal into the state file. A crash after the
// state file is written but before the journal is removed is harmless: the
// journal replays to the same values.
func CompactCheckpoint(statePath, journalPath string, checkpoint Checkpoint) error {
	if err := WriteCheckpoint(statePath, checkpoint); err != nil {
		return err
	}
	if err := os.Remove(journalPath); err != nil && !os.IsNotExist(err) {
		return err
	}
	return syncDirectory(filepath.Dir(journalPath))
}

type Journal struct{ file *os.File }

func OpenJournal(path string, checkpoint Checkpoint) (*Journal, error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0600)
	if err != nil {
		return nil, err
	}
	journal := &Journal{file: file}
	info, err := file.Stat()
	if err == nil && info.Size() == 0 {
		if err = journal.write(journalLine{SnapshotHash: checkpoint.SnapshotHash}); err == nil {
			err = syncDirectory(filepath.Dir(path))
		}
	}
	if err != nil {
		file.Close()
		return nil, err
	}
	return journal, nil
}
func (j *Journal) write(line journalLine) error {
	data, err := json.Marshal(line)
	if err != nil {
		return err
	}
	if _, err = j.file.Write(append(data, '\n')); err != nil {
		return err
	}
	return j.file.Sync()
}

// Append durably records one entry's progress before returning.
func (j *Journal) Append(id string, progress Progress) error {
	return j.write(journalLine{ID: id, Progress: &progress})
}
func (j *Journal) Close() error { return j.file.Close() }
