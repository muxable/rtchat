// Package observability sends operational issues to Google Error Reporting via
// structured Cloud Logging entries. It preserves messages used by log metrics.
package observability

import (
	"errors"
	"fmt"
	"runtime/debug"
	"strings"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Version = "development"

type PanicError struct {
	Value any
	Stack string
}

func (e *PanicError) Error() string { return fmt.Sprintf("panic: %v", e.Value) }
func CapturePanic(value any) error  { return &PanicError{Value: value, Stack: string(debug.Stack())} }

type reportingCore struct {
	zapcore.Core
	fields []zapcore.Field
}

func Wrap(core zapcore.Core) zapcore.Core { return &reportingCore{Core: core} }
func (c *reportingCore) With(fields []zapcore.Field) zapcore.Core {
	all := append(append([]zapcore.Field(nil), c.fields...), fields...)
	return &reportingCore{Core: c.Core.With(fields), fields: all}
}
func (c *reportingCore) Check(entry zapcore.Entry, checked *zapcore.CheckedEntry) *zapcore.CheckedEntry {
	if c.Enabled(entry.Level) {
		return checked.AddCore(entry, c)
	}
	return checked
}
func (c *reportingCore) Write(entry zapcore.Entry, fields []zapcore.Field) error {
	if entry.Level < zapcore.WarnLevel {
		return c.Core.Write(entry, fields)
	}
	stack := entry.Stack
	message := entry.Message
	all := append(append([]zapcore.Field(nil), c.fields...), fields...)
	for _, field := range all {
		if field.Type == zapcore.ErrorType {
			if err, ok := field.Interface.(error); ok {
				message += ": " + err.Error()
				var panicErr *PanicError
				if errors.As(err, &panicErr) {
					stack = panicErr.Stack
				}
			}
		}
		if field.Key == "crash_stack" {
			stack = field.String
		}
	}
	output := make([]zapcore.Field, 0, len(fields)+4)
	for _, field := range fields {
		if field.Key != "crash_stack" {
			output = append(output, field)
		}
	}
	fields = append(output,
		zap.String("@type", "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"),
		zap.Any("serviceContext", map[string]string{"service": "rtchat-agent", "version": Version}),
		zap.String("stack_trace", strings.TrimSpace(message+"\n"+stack)),
		zap.Any("context", map[string]any{"reportLocation": map[string]any{"filePath": entry.Caller.File, "lineNumber": entry.Caller.Line, "functionName": entry.Caller.Function}}),
	)
	return c.Core.Write(entry, fields)
}

// HTTPLogWriter preserves net/http's recovered panic and original goroutine stack.
type HTTPLogWriter struct{ Logger *zap.Logger }

func (w HTTPLogWriter) Write(p []byte) (int, error) {
	w.Logger.Error("HTTP server error", zap.String("crash_stack", strings.TrimSpace(string(p))))
	return len(p), nil
}
