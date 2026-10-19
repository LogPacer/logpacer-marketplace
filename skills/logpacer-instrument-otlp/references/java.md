# Java

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry agent and SDK read them from that environment.

## Zero-code (recommended)

Download `opentelemetry-javaagent.jar` from the opentelemetry-java-instrumentation releases on GitHub. Pin one version and ship it with the app (in the image, or beside the jar) instead of downloading it at start.

```sh
java -javaagent:/opt/otel/opentelemetry-javaagent.jar -jar app.jar
```

When the start command is fixed (an app server, a container base image), set `JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar"` in the same environment.

The agent instruments servlet containers, Spring, HTTP clients, JDBC, messaging and more, and reads `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_PROTOCOL`, the per-signal endpoint variables and the `OTEL_*_EXPORTER` variables. It exports logs by default; the guide's `OTEL_LOGS_EXPORTER=none` turns that off, so keep it. The agent also puts `trace_id` and `span_id` into the logging MDC (see `logpacer-logging-setup`).

## SDK

Without the agent:

- **Spring Boot:** add `io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter` with the `opentelemetry-instrumentation-bom` BOM. It reads the same variables.
- **Plain SDK:** add `io.opentelemetry:opentelemetry-sdk-extension-autoconfigure` and `io.opentelemetry:opentelemetry-exporter-otlp` (with the `opentelemetry-bom` BOM), and build the SDK from the environment once at startup:

```java
OpenTelemetry otel = AutoConfiguredOpenTelemetrySdk.initialize().getOpenTelemetrySdk();
```

A custom span:

```java
Tracer tracer = otel.getTracer("checkout"); // with the agent: GlobalOpenTelemetry.getTracer("checkout")
Span span = tracer.spanBuilder("charge card").startSpan();
try (Scope scope = span.makeCurrent()) {
  charge(order);
} finally {
  span.end();
}
```

With the agent, annotating a method with `@WithSpan` (from `io.opentelemetry.instrumentation:opentelemetry-instrumentation-annotations`) does the same.

Leave log export off; for trace ids in log lines see `logpacer-logging-setup`.
