# Node.js: trace ids in log lines

Keep the app's logger and format. The ids come from the active OpenTelemetry span, so instrument the app first (`logpacer-instrument-otlp`).

## pino (JSON)

`@opentelemetry/instrumentation-pino`, part of `@opentelemetry/auto-instrumentations-node`, adds `trace_id`, `span_id` and `trace_flags` fields to every record written inside a span. With the auto-instrumentations loaded, nothing else is needed. With a hand-built SDK, add `new PinoInstrumentation()` to its `instrumentations`.

## winston

`@opentelemetry/instrumentation-winston`, also part of the auto-instrumentations, adds `trace_id` and `span_id` to each record's metadata. A JSON format prints them as fields. A text format prints only what its template names, so add them at the end:

```js
const { format } = require('winston');

const line = format.printf(({ timestamp, level, message, trace_id, span_id }) =>
  `${timestamp} ${level} ${message}` + (trace_id ? ` trace_id=${trace_id} span_id=${span_id}` : ''));
```

## console or a custom logger

Read the ids from the active span:

```js
const { trace } = require('@opentelemetry/api');

function traceFields() {
  const context = trace.getActiveSpan()?.spanContext();
  return context ? ` trace_id=${context.traceId} span_id=${context.spanId}` : '';
}

console.log(`payment captured order=${order.id}${traceFields()}`);
```

For a JSON logger, add `trace_id` and `span_id` properties from the same `spanContext()` instead.

Do not add an OpenTelemetry log exporter or log transport: EdgePacer collects the app's output.
