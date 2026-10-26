Agent issue reporting
=====================

On GCE, every Zap warning or higher is a structured Google Error Reporting event
for service `rtchat-agent`. The Docker build supplies the commit SHA as its version.
`stack_trace` includes the error cause and stack; original log messages and metric
labels stay intact. Routine client errors remain informational. Callable panics
retain their original value and stack privately while returning generic INTERNAL
responses. Public HTTP failures and net/http's recovered panics also report.

The production container starts a supervisor and worker. The worker uses Go's
`debug.SetCrashOutput` to send fatal runtime diagnostics to a pipe owned by the
supervisor, which survives goroutine panics and emits one structured crash event.
Nonzero exits and signals without a Go stack still report the exit reason. SIGTERM
is forwarded to preserve the worker's existing graceful shutdown. Direct `go run
./cmd` does not enable the supervisor; use `go run ./cmd --supervise` to exercise it.

Hard kills of the entire container or machine cannot run a reporter. The existing
chat-throughput alert detects loss of service. Crash payloads retain at most 128 KiB
to stay within Cloud Logging entry limits; full runtime output also goes to stderr.
Do not log credentials, tokens, or request bodies: warnings and errors become
issue records as well as ordinary logs.

The `Agent issues` log alert uses existing notification destinations and limits
notifications to one per hour without limiting recorded events. Reconcile alerts
with `python3 monitoring/apply_alerts.py` (read-only) or add `--apply` to write.
The same reconciliation is included in `monitoring/apply.sh`.

References:
- https://docs.cloud.google.com/error-reporting/docs/formatting-error-messages
- https://pkg.go.dev/runtime/debug#SetCrashOutput
