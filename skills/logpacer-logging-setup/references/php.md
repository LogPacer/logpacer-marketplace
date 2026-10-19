# PHP: trace ids in log lines

Keep the app's logger and format. The ids come from the current OpenTelemetry span, so instrument the app first (`logpacer-instrument-otlp`).

## Monolog

Add a processor that puts the ids in the record's `extra`. Monolog's default `LineFormatter` prints `extra` at the end of the line and JSON formatters print it as fields, so the app's format stays as it is.

Monolog 3:

```php
use Monolog\LogRecord;
use OpenTelemetry\API\Trace\Span;

$logger->pushProcessor(function (LogRecord $record): LogRecord {
    $context = Span::getCurrent()->getContext();
    if ($context->isValid()) {
        $record->extra['trace_id'] = $context->getTraceId();
        $record->extra['span_id'] = $context->getSpanId();
    }
    return $record;
});
```

Monolog 2 passes arrays: set `$record['extra']['trace_id']` and `$record['extra']['span_id']` the same way.

In Laravel, attach the processor with a `tap` class on the log channel in `config/logging.php`. In Symfony, register it as a service tagged `monolog.processor`.

## Other PSR-3 loggers

Add `trace_id` and `span_id` from `Span::getCurrent()->getContext()` to each record's context where the logger builds its line.

Do not add an OpenTelemetry log handler that exports records: EdgePacer collects the app's output.
