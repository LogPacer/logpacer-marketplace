# PHP

Get the environment first: `logpacer otlp env --service <name> --mode <mode>`, or the mode's `env` map from `get_guide` topic `otlp`. Nothing here names an endpoint or port; the OpenTelemetry packages read them from that environment.

## Zero-code

Zero-code PHP instrumentation needs the `opentelemetry` extension plus the SDK and an auto-instrumentation package for the framework:

```sh
pecl install opentelemetry
composer require open-telemetry/sdk open-telemetry/exporter-otlp php-http/guzzle7-adapter
composer require open-telemetry/opentelemetry-auto-laravel   # or -auto-symfony, -auto-slim, -auto-psr18, -auto-pdo ...
```

Enable the extension in `php.ini` (`extension=opentelemetry`) and add `OTEL_PHP_AUTOLOAD_ENABLED=true` to the guide's variables. The exporter needs a PSR-18 HTTP client; `php-http/guzzle7-adapter` is one, and any the app already has works.

PHP-FPM passes workers only the variables the pool allows. Add each variable to the pool config as `env[OTEL_SERVICE_NAME] = checkout` (and so on for the guide's variables), or set `clear_env = no`, then reload PHP-FPM. Under Apache `mod_php`, use `SetEnv`. Check with a `phpinfo()` page or `getenv()` in a request, then remove the check.

## SDK

With `OTEL_PHP_AUTOLOAD_ENABLED=true`, the SDK builds the global tracer provider from the environment. A custom span:

```php
use OpenTelemetry\API\Globals;

$tracer = Globals::tracerProvider()->getTracer('checkout');
$span = $tracer->spanBuilder('charge card')->startSpan();
$scope = $span->activate();
try {
    charge($order);
} finally {
    $scope->detach();
    $span->end();
}
```

Without the extension, only spans you create by hand are recorded; the auto-instrumentation packages need it.

Leave log export off (`OTEL_LOGS_EXPORTER=none`); for trace ids in log lines see `logpacer-logging-setup`.
