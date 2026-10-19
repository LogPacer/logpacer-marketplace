# Python

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry packages read them from that environment.

Install the exporter that matches the guide's `OTEL_EXPORTER_OTLP_PROTOCOL`: `opentelemetry-exporter-otlp-proto-http` for `http/protobuf`. With only the gRPC exporter installed, exports fail.

## Zero-code

```sh
pip install opentelemetry-distro opentelemetry-exporter-otlp-proto-http
opentelemetry-bootstrap -a install   # adds instrumentations for the libraries the app has installed
```

Add both to the app's requirements file rather than installing ad hoc, then start the app through the wrapper with the environment loaded:

```sh
opentelemetry-instrument python app.py
opentelemetry-instrument gunicorn app:app
opentelemetry-instrument uvicorn app:app
```

Pre-fork servers (gunicorn or uWSGI with several workers) and reloaders can lose the exporter in worker processes. If spans are missing from workers, follow the OpenTelemetry Python docs on forking servers and set up the SDK in the post-fork hook.

## SDK

For custom spans or explicit setup:

```python
from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import os

# service.name comes from OTEL_SERVICE_NAME, endpoints from the per-signal variables.
provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
trace.set_tracer_provider(provider)

if os.environ.get("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT"):
    reader = PeriodicExportingMetricReader(OTLPMetricExporter())
    metrics.set_meter_provider(MeterProvider(metric_readers=[reader]))
```

Run it once at startup, before the web framework is created, and add the instrumentation package for each library you want traced (for example `opentelemetry-instrumentation-flask` with `FlaskInstrumentor().instrument_app(app)`).

A custom span:

```python
tracer = trace.get_tracer("checkout")

with tracer.start_as_current_span("charge card"):
    charge(order)
```

Leave log export off (`OTEL_LOGS_EXPORTER=none`); for trace ids in log lines see `logpacer-logging-setup`.
