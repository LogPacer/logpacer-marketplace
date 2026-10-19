# Ruby: trace ids in log lines

Keep the app's logger and format. The ids come from the current OpenTelemetry span, so instrument the app first (`logpacer-instrument-otlp`).

## Rails and the standard Logger

Append the ids to each line through a formatter that keeps the existing output:

```ruby
# config/initializers/trace_id_log_formatter.rb
class TraceIdLogFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, time, progname, message)
    context = OpenTelemetry::Trace.current_span.context
    line = super
    return line unless context.valid?

    "#{line.chomp} trace_id=#{context.hex_trace_id} span_id=#{context.hex_span_id}\n"
  end
end
```

```ruby
# config/application.rb (or the environment file that sets the logger)
config.log_formatter = TraceIdLogFormatter.new
```

Tagged logging keeps working: Rails prepends the tags before this formatter runs. If the app already has its own formatter, add the same two keys to it instead of replacing it.

Outside Rails, subclass `Logger::Formatter` the same way and assign it with `logger.formatter = TraceIdLogFormatter.new`.

## JSON loggers (lograge, semantic_logger)

Add `trace_id` and `span_id` fields from `OpenTelemetry::Trace.current_span.context` (`hex_trace_id`, `hex_span_id`) in the logger's per-request hook, such as lograge's `custom_options`, when `context.valid?`.

Do not add an OpenTelemetry log exporter: EdgePacer collects the app's output.
