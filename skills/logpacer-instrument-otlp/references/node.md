# Node.js

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry packages read them from that environment.

## Zero-code

```sh
npm install --save @opentelemetry/api @opentelemetry/auto-instrumentations-node
```

Start the app with the register hook, with the environment loaded:

```sh
node --require @opentelemetry/auto-instrumentations-node/register app.js
```

When the start command cannot change (a platform's `npm start`, a process manager), set `NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register"` in the same environment instead.

The hook instruments HTTP, common frameworks, database clients and loggers, and reads `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_PROTOCOL`, the per-signal endpoint variables and the `OTEL_*_EXPORTER` variables. To quiet noisy instrumentations, list the ones to keep in `OTEL_NODE_ENABLED_INSTRUMENTATIONS` (for example `http,express,pg`).

## SDK

Use the SDK for custom spans, metrics, or ES module apps. Pick the exporter packages that match the guide's `OTEL_EXPORTER_OTLP_PROTOCOL`: the `-proto` packages speak `http/protobuf`.

```sh
npm install --save @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/sdk-metrics \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-proto @opentelemetry/exporter-metrics-otlp-proto
```

```js
// instrumentation.js, loaded before the app
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-proto');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-proto');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');

const sdk = new NodeSDK({
  // Endpoints come from OTEL_EXPORTER_OTLP_TRACES_ENDPOINT and _METRICS_ENDPOINT.
  traceExporter: new OTLPTraceExporter(),
  metricReader: process.env.OTEL_EXPORTER_OTLP_METRICS_ENDPOINT
    ? new PeriodicExportingMetricReader({ exporter: new OTLPMetricExporter() })
    : undefined,
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
process.on('SIGTERM', () => sdk.shutdown().finally(() => process.exit(0)));
```

Start with `node --require ./instrumentation.js app.js`. ES module apps load an `.mjs` version with `node --import ./instrumentation.mjs app.mjs`, plus the module loader hook the OpenTelemetry JavaScript docs give for the app's Node.js version.

A custom span:

```js
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('checkout');

await tracer.startActiveSpan('charge card', async (span) => {
  try {
    await charge(order);
  } finally {
    span.end();
  }
});
```

Leave log export off (`OTEL_LOGS_EXPORTER=none`); for trace ids in log lines see `logpacer-logging-setup`.
