# Python: trace ids in log lines

Keep the app's logger and format. The ids come from the active OpenTelemetry span, so instrument the app first (`logpacer-instrument-otlp`).

## Standard library `logging`

`opentelemetry-instrumentation-logging` (installed by `opentelemetry-bootstrap` and active under `opentelemetry-instrument`) adds `otelTraceID` and `otelSpanID` to every log record. Reference them in the app's existing format string:

```python
logging.Formatter(
    "%(asctime)s %(levelname)s %(name)s %(message)s trace_id=%(otelTraceID)s span_id=%(otelSpanID)s"
)
```

Outside a span the values are `0`. Leave `OTEL_PYTHON_LOG_CORRELATION` unset: it makes the instrumentation configure logging with OpenTelemetry's own format when the app has not configured logging yet. With a hand-built SDK, call `LoggingInstrumentor().instrument(set_logging_format=False)` from `opentelemetry.instrumentation.logging` once at startup.

In Django, put the same format in the `LOGGING` setting's formatter.

## structlog or another JSON logger

Add a processor before the renderer:

```python
from opentelemetry import trace

def add_trace_ids(logger, method_name, event_dict):
    context = trace.get_current_span().get_span_context()
    if context.is_valid:
        event_dict["trace_id"] = format(context.trace_id, "032x")
        event_dict["span_id"] = format(context.span_id, "016x")
    return event_dict
```

For `python-json-logger`, reference `otelTraceID` and `otelSpanID` in its format and rename them to `trace_id` and `span_id` with its `rename_fields` option.

Do not add an OpenTelemetry log handler or exporter: EdgePacer collects the app's output.
