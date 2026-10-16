# Java: trace ids in log lines

Keep the app's logger and format. The ids come from the active OpenTelemetry span, so instrument the app first (`logpacer-instrument-otlp`).

## With the OpenTelemetry Java agent

The agent puts `trace_id`, `span_id` and `trace_flags` into the MDC of Logback and Log4j 2 for every log call inside a span. Add them to the existing pattern.

Logback (`logback.xml`, `logback-spring.xml`):

```xml
<pattern>%d{ISO8601} %-5level [%thread] %logger{36} - %msg trace_id=%X{trace_id} span_id=%X{span_id}%n</pattern>
```

Log4j 2 (`log4j2.xml`):

```xml
<PatternLayout pattern="%d{ISO8601} %-5level [%t] %c{1} - %msg trace_id=%X{trace_id} span_id=%X{span_id}%n"/>
```

Spring Boot without a logging config file: append the same keys through `logging.pattern.console` (and `logging.pattern.file`), keeping the rest of the default pattern.

JSON encoders such as `logstash-logback-encoder` include MDC entries as fields already.

## Without the agent

- Logback: add `io.opentelemetry.instrumentation:opentelemetry-logback-mdc-1.0` and wrap the existing appender in `io.opentelemetry.instrumentation.logback.mdc.v1_0.OpenTelemetryAppender`.
- Log4j 2: add `io.opentelemetry.instrumentation:opentelemetry-log4j-context-data-2.17-autoconfigure`; it fills the context data on its own.

The MDC keys and patterns are then the same as above.

Do not add the OpenTelemetry log appender that exports log records: EdgePacer collects the app's output, and the guide keeps `OTEL_LOGS_EXPORTER=none`.
