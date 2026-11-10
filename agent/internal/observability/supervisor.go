package observability

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime/debug"
	"strconv"
	"strings"
	"syscall"

	"go.uber.org/zap"
)

const crashFD = "RTCHAT_CRASH_FD"

// InstallCrashOutput connects runtime fatal errors, including panics on other
// goroutines, to the supervisor. The runtime duplicates the descriptor.
func InstallCrashOutput() error {
	value := os.Getenv(crashFD)
	if value == "" {
		return nil
	}
	fd, err := strconv.Atoi(value)
	if err != nil {
		return err
	}
	file := os.NewFile(uintptr(fd), "crash-output")
	defer file.Close()
	return debug.SetCrashOutput(file, debug.CrashOptions{})
}

// Supervise runs the worker in a separate process so a fatal runtime crash cannot
// stop its crash reporter. Context cancellation forwards SIGTERM for normal drain.
func Supervise(ctx context.Context, cmd *exec.Cmd, logger *zap.Logger) int {
	reader, writer, err := os.Pipe()
	if err != nil {
		logger.Error("create crash pipe", zap.Error(err))
		return 1
	}
	defer reader.Close()
	cmd.ExtraFiles = append(cmd.ExtraFiles, writer)
	env := cmd.Env
	if env == nil {
		env = os.Environ()
	}
	cmd.Env = nil
	for _, item := range env {
		if !strings.HasPrefix(item, crashFD+"=") {
			cmd.Env = append(cmd.Env, item)
		}
	}
	// ExtraFiles start at descriptor 3.
	cmd.Env = append(cmd.Env, fmt.Sprintf("%s=%d", crashFD, len(cmd.ExtraFiles)+2))
	output := make(chan string, 1)
	go func() {
		// Bound the log entry, but drain the pipe so runtime crash writes cannot block.
		data, _ := io.ReadAll(io.LimitReader(reader, 128*1024))
		_, _ = io.Copy(io.Discard, reader)
		output <- string(data)
	}()
	if err := cmd.Start(); err != nil {
		writer.Close()
		logger.Error("start agent worker", zap.Error(err))
		return 1
	}
	writer.Close()
	done := make(chan struct{})
	go func() {
		select {
		case <-ctx.Done():
			_ = cmd.Process.Signal(syscall.SIGTERM)
		case <-done:
		}
	}()
	err = cmd.Wait()
	close(done)
	stack := <-output
	if stack != "" {
		logger.Error("agent worker crashed", zap.String("crash_stack", stack))
	} else if err != nil {
		logger.Error("agent worker exited unexpectedly", zap.Error(err))
	}
	if err != nil {
		return 1
	}
	return 0
}
