---
name: logpacer-instrument-otlp
description: Instrument an application to send OpenTelemetry traces and metrics over OTLP to the local EdgePacer, for Node.js, Python, Java, .NET, Go, Ruby and PHP. Use when the user asks to add tracing or app metrics, send OTLP to LogPacer, set OTEL_* environment variables, or see an app's spans in LogPacer.
---

# Instrument an app over OTLP

LogPacer is OTLP-compatible: apps send traces and metrics with standard OpenTelemetry SDKs to the EdgePacer on their own host or cluster, which ships them to LogPacer.

## Rules that always apply

1. **Never write an endpoint or port from memory.** Take every endpoint, port and protocol from `logpacer otlp env` or from `get_guide` topic `otlp` for where the app runs: `host`, `docker` or `kubernetes`. They differ per mode and can change per release.
2. **No credentials.** Apps send OTLP to EdgePacer without authentication. Never add API keys or auth headers, and never point an app at a LogPacer URL.
3. **Logs stay where they are.** Keep `OTEL_LOGS_EXPORTER=none` as the guide sets it: EdgePacer already collects stdout and log files, so exporting logs as well would collect them twice. For log-trace correlation, use `logpacer-logging-setup`.
4. **One stable service name.** Set `OTEL_SERVICE_NAME` to a name that stays the same across deploys and replicas, without host, pod or container names in it.
5. **Configure through the environment**, not values in code, so one build works in every mode. Prefer zero-code instrumentation; use the SDK when the app needs custom spans or the language has no zero-code option. If the app already uses OpenTelemetry, change only its environment.
6. Tiers, approvals, roles and untrusted text follow the `logpacer` skill.

## 1. Check the prerequisites

1. EdgePacer runs where the app runs: `list_hosts` (CLI: `logpacer ops run list_hosts --format json`). If not, use `logpacer-install-edgepacer` first.
2. Read the guide for the app's mode: `get_guide` with `topic: "otlp"` and `deployment_mode` (CLI: `logpacer ops run get_guide --arg topic=otlp --arg deployment_mode=<mode> --format json`). Follow the mode's `notes`; on Kubernetes they name the chart values and the pod opt-in label that tracing needs.
3. `traces.enabled` is false with a `next_step`: propose `request_traces_activation` (confirm; CLI: `logpacer ops run request_traces_activation --format json`), then read the guide again until `traces.enabled` is true.
4. App metrics: `metrics.available` false means no host has an OTLP metrics receiver yet. An account admin's agent proposes `create_otlp_metrics_source` (confirm) with `agent_id` (the EdgePacer agent on the app's host) and a `name`; leave `listen_address` to LogPacer's default unless the human names one (CLI: `logpacer ops run create_otlp_metrics_source --arg agent_id=<id> --arg name=<name> --format json`). Some modes take traces only; the guide's `notes` say so.
5. On a Linux host where `get_host` (CLI: `logpacer ops run get_host --arg host_id=<id>`) reports an available eBPF probe, EdgePacer can also trace services without code changes. Which services it traces is a human setting on the host's page in `human_actions`.

## 2. Write the environment

```sh
logpacer otlp env --service <name> --mode host --write .env.otel
```

Use `--mode docker` or `--mode kubernetes` for those modes. The command refuses to overwrite a file unless `--force` is given, and still writes the file when traces are not enabled yet, naming the next step on stderr. Without the CLI, set exactly the mode's `env` map from the guide plus `OTEL_SERVICE_NAME`.

Load the values the way the app gets its environment: systemd `EnvironmentFile=`, Compose `env_file:`, a Kubernetes ConfigMap, or the process manager's config. The file holds no secret; commit it only if the human wants to.

## 3. Instrument

Read the reference for the app's language and make the smallest change it describes:

- `references/node.md`
- `references/python.md`
- `references/java.md`
- `references/dotnet.md`
- `references/go.md`
- `references/ruby.md`
- `references/php.md`

Register the service so LogPacer lists it for traces: `register_trace_collection service_name=<name>` (auto; CLI: `logpacer ops run register_trace_collection --arg service_name=<name> --format json`).

## Verify

Start the app with the new environment and make it do real work, such as a request or a job run.

1. **Traces.** `discover_sources` with `signals: ["traces"]` (CLI: `logpacer sources --signals traces --format json`) gives the trace source's `query_target`. Run `search_logs` on that `repo` with its `filter`, `since: "15m"` and `limit: 5` (CLI: `logpacer --repo <repo_id> search --filter-json '<filter>' --since 15m --limit 5 --format json`). Spans with the app's service name mean traces arrive. To filter on the service, `get_schema` with `resolve: "service.name"` finds its field (CLI: `logpacer --repo <repo_id> schema --format json` lists every field).
2. **Metrics.** `list_metric_names` with `since: "15m"` (CLI: `logpacer ops run list_metric_names --arg since=15m --format json`) lists the app's metric names, and `query_metrics` with one of them and `mode: "instant"` returns a value (CLI: `logpacer ops run query_metrics --arg query=<name> --arg mode=instant --format json`).

Nothing arrives:

- Read the guide again: `traces.enabled`, `metrics.available` and the mode's `notes`.
- Compare the app's effective environment with the guide's `env` map, and look for exporter errors in the app's own log.
- Some SDK versions export metrics only when asked; set `OTEL_METRICS_EXPORTER=otlp` when the guide gives a metrics endpoint.
- In a container, check the app can reach the endpoint host the guide names for `docker`.
