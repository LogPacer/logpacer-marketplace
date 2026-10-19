# Go

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry exporters read them from that environment.

## Zero-code

Go has no mature zero-code agent; use the SDK below. On a Linux host where EdgePacer's eBPF probe is available, EdgePacer can trace services without code changes; a human chooses which on the host's page in LogPacer.

## SDK

Go picks the protocol by exporter package, not by `OTEL_EXPORTER_OTLP_PROTOCOL`. For `http/protobuf`, use the `otlptracehttp` and `otlpmetrichttp` exporters.

```sh
go get go.opentelemetry.io/otel go.opentelemetry.io/otel/sdk go.opentelemetry.io/otel/sdk/metric \
  go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp \
  go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp \
  go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
```

```go
// Endpoints come from OTEL_EXPORTER_OTLP_TRACES_ENDPOINT and _METRICS_ENDPOINT;
// the default resource reads OTEL_SERVICE_NAME.
func setupTelemetry(ctx context.Context) (shutdown func(context.Context) error, err error) {
	traceExporter, err := otlptracehttp.New(ctx)
	if err != nil {
		return nil, err
	}
	tracerProvider := sdktrace.NewTracerProvider(sdktrace.WithBatcher(traceExporter))
	otel.SetTracerProvider(tracerProvider)
	otel.SetTextMapPropagator(propagation.TraceContext{})
	shutdowns := []func(context.Context) error{tracerProvider.Shutdown}

	if os.Getenv("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT") != "" {
		metricExporter, err := otlpmetrichttp.New(ctx)
		if err != nil {
			return nil, err
		}
		meterProvider := sdkmetric.NewMeterProvider(sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricExporter)))
		otel.SetMeterProvider(meterProvider)
		shutdowns = append(shutdowns, meterProvider.Shutdown)
	}

	return func(ctx context.Context) error {
		var errs []error
		for _, shutdown := range shutdowns {
			errs = append(errs, shutdown(ctx))
		}
		return errors.Join(errs...)
	}, nil
}
```

Call it first in `main` and defer the shutdown so buffered spans are flushed on exit. Wrap HTTP servers and clients:

```go
http.Handle("/", otelhttp.NewHandler(mux, "server"))
client := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
```

Instrumentation for gRPC, database/sql and other libraries lives under `go.opentelemetry.io/contrib/instrumentation`. To let the environment choose the exporter instead, `go.opentelemetry.io/contrib/exporters/autoexport` reads `OTEL_TRACES_EXPORTER`, `OTEL_METRICS_EXPORTER` and the protocol variable.

A custom span:

```go
ctx, span := otel.Tracer("checkout").Start(ctx, "charge card")
defer span.End()
```

Pass `ctx` on, so child spans and log lines see the active span. For trace ids in log lines see `logpacer-logging-setup`.
