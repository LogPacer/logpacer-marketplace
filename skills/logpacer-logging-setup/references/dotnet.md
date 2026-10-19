# .NET: trace ids in log lines

Keep the app's logger and format. The ids come from the current `Activity`, which OpenTelemetry instrumentation starts for each request, so instrument the app first (`logpacer-instrument-otlp`).

## Serilog

Serilog 3.1 and later records the current trace and span ids on every event, and current sinks print them as `{TraceId}` and `{SpanId}`. Add them to the existing output template:

```csharp
.WriteTo.Console(outputTemplate:
    "{Timestamp:o} [{Level:u3}] {Message:lj} trace_id={TraceId} span_id={SpanId}{NewLine}{Exception}")
```

JSON formatters such as `CompactJsonFormatter` write them as fields already. On older Serilog versions, add the `Serilog.Enrichers.Span` enricher.

## NLog

Add `NLog.DiagnosticSource` and append to the layout:

```
${longdate} ${level:uppercase=true} ${logger} ${message} trace_id=${activity:property=TraceId} span_id=${activity:property=SpanId}
```

## Microsoft.Extensions.Logging console

The built-in console formatters print scopes. Open one per request with the ids as key=value text, and turn scopes on:

```csharp
builder.Logging.AddSimpleConsole(options => options.IncludeScopes = true);

var app = builder.Build();
app.Use(async (context, next) =>
{
    var activity = Activity.Current;
    using (activity is null ? null : app.Logger.BeginScope(
        "trace_id={TraceId} span_id={SpanId}", activity.TraceId, activity.SpanId))
    {
        await next();
    }
});
```

Register it before the endpoints, after the OpenTelemetry instrumentation starts the request's activity. The JSON console formatter (`AddJsonConsole` with `IncludeScopes`) writes the same scope values as fields.

Do not add an OpenTelemetry logging provider with an exporter: EdgePacer collects the app's output.
