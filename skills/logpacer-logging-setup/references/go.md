# Go: trace ids in log lines

Keep the app's logger and format. The ids come from the span in the request's `context.Context`, so instrument the app first (`logpacer-instrument-otlp`) and log with the context.

## log/slog

Wrap the app's existing handler so every record logged with a context that holds a span gets the ids. A `TextHandler` writes them as key=value pairs, a `JSONHandler` as fields, matching what the app already writes:

```go
import (
	"context"
	"log/slog"

	"go.opentelemetry.io/otel/trace"
)

type traceHandler struct{ slog.Handler }

func (h traceHandler) Handle(ctx context.Context, record slog.Record) error {
	if spanContext := trace.SpanContextFromContext(ctx); spanContext.IsValid() {
		record.AddAttrs(
			slog.String("trace_id", spanContext.TraceID().String()),
			slog.String("span_id", spanContext.SpanID().String()),
		)
	}
	return h.Handler.Handle(ctx, record)
}

func (h traceHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return traceHandler{h.Handler.WithAttrs(attrs)}
}

func (h traceHandler) WithGroup(name string) slog.Handler {
	return traceHandler{h.Handler.WithGroup(name)}
}

// logger := slog.New(traceHandler{existingHandler})
```

Log with the context-taking methods (`logger.InfoContext(ctx, ...)`, `logger.ErrorContext(ctx, ...)`); the plain ones pass no span.

## zap, zerolog, logrus

Add the same two fields from `trace.SpanContextFromContext(ctx)` where the app builds its request-scoped logger, for example `logger.With(zap.String("trace_id", ...), zap.String("span_id", ...))`.

Do not use the `otelslog` bridge or another OpenTelemetry log exporter: they send logs over OTLP, and EdgePacer already collects the app's output.
