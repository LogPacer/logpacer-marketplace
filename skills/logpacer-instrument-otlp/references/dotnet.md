# .NET

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry packages read them from that environment.

## Zero-code

OpenTelemetry .NET Automatic Instrumentation instruments ASP.NET Core, HttpClient, SQL clients and more without code changes. Install it with the project's installer for the OS (the `otel-dotnet-auto-install.sh` script on Linux and macOS, the `OpenTelemetry.DotNet.Auto.psm1` PowerShell module on Windows) from its GitHub releases, or add the `OpenTelemetry.AutoInstrumentation` NuGet package to the app. Then start the app the way the project's docs describe (its `instrument.sh`, or `Register-OpenTelemetryForCurrentSession` / `Register-OpenTelemetryForIIS` on Windows), with the environment loaded. It reads `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_PROTOCOL`, the per-signal endpoint variables and the `OTEL_*_EXPORTER` variables.

## SDK (ASP.NET Core)

```sh
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
```

```csharp
// Program.cs. service.name comes from OTEL_SERVICE_NAME; the exporter reads the
// endpoint and protocol variables.
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => tracing
        .AddSource("Checkout")
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter())
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter());
```

- Leave out `.WithMetrics(...)` when the guide gives no metrics endpoint (it sets `OTEL_METRICS_EXPORTER=none`, which the SDK alone does not read).
- Do not add `builder.Logging.AddOpenTelemetry(...)` with an exporter: EdgePacer already collects the app's console and file logs.
- Use a current release of `OpenTelemetry.Exporter.OpenTelemetryProtocol`. If an old release ignores the per-signal endpoint variables, upgrade it rather than writing the endpoint into code.

A custom span uses `System.Diagnostics.ActivitySource`, registered with `.AddSource("Checkout")` above:

```csharp
private static readonly ActivitySource Source = new("Checkout");

using (var activity = Source.StartActivity("charge card"))
{
    await ChargeAsync(order);
}
```

For trace ids in log lines see `logpacer-logging-setup`.
