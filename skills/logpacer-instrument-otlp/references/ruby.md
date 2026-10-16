# Ruby

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry gems read them from that environment.

## Zero-code (two lines)

Ruby has no separate agent: the SDK with every available instrumentation is the zero-code option.

```ruby
# Gemfile
gem "opentelemetry-sdk"
gem "opentelemetry-exporter-otlp"
gem "opentelemetry-instrumentation-all"
```

```ruby
# config/initializers/opentelemetry.rb in Rails, or before the app boots elsewhere.
# service.name comes from OTEL_SERVICE_NAME, endpoint and protocol from OTEL_EXPORTER_OTLP_*.
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/all"

OpenTelemetry::SDK.configure(&:use_all)
```

`use_all` instruments Rack, Rails, Sidekiq, Net::HTTP, Faraday, PG, MySQL2, Redis and the other libraries the app loads. The `opentelemetry-exporter-otlp` gem speaks `http/protobuf`. To trace fewer libraries, replace `use_all` with `c.use "OpenTelemetry::Instrumentation::Rails"` and the others you want.

## SDK

A custom span:

```ruby
CheckoutTracer = OpenTelemetry.tracer_provider.tracer("checkout")

CheckoutTracer.in_span("charge card") do |span|
  charge(order)
end
```

App metrics need the `opentelemetry-metrics-sdk` and `opentelemetry-exporter-otlp-metrics` gems, which are still pre-1.0. Add them only when the human wants app metrics and the guide gives a metrics endpoint, and follow those gems' READMEs.

Leave log export off (`OTEL_LOGS_EXPORTER=none`); for trace ids in log lines see `logpacer-logging-setup`.
