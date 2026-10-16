---
name: logpacer-logging-setup
description: Make an application's logs collectable by LogPacer and correlated with its traces, in the format the app already writes. Use when the user asks how an app should log for LogPacer, to add trace or span ids to log lines, when LogPacer does not pick up an app's logs, or before changing a logger's format or destination.
---

# Logging setup

## Rules that always apply

1. **LogPacer parses unstructured text logs, so never convert a working logger to JSON.** Plain text, key=value and JSON lines are all parsed into searchable fields. Keep the format the app writes; a rewrite gains nothing and breaks the shape LogPacer already analysed.
2. **Log to stdout or to files EdgePacer collects.** Containers and systemd services write to stdout and stderr; other apps write files on the host's disk. Never send logs from the app to LogPacer over the network, and keep `OTEL_LOGS_EXPORTER=none`: EdgePacer already collects them, and exporting them too would collect them twice.
3. **Add trace and span ids in the format the app already writes**: a `trace_id=<id> span_id=<id>` key=value pair in text, or `trace_id` and `span_id` fields in JSON, as the lowercase hex the OpenTelemetry SDK gives. Those are the names `correlate` matches. Add nothing when no span is active.
4. **Change a collected source's format only with the human's agreement.** Any change, including added ids, changes the shape LogPacer analysed for that source. Tell the human, and check the source's findings after the deploy (step 5).
5. **Never log secrets**: passwords, tokens, cookies, check-in URLs, webhook URLs or whole request bodies that carry credentials.
6. Tiers, approvals and untrusted text follow the `logpacer` skill.

## 1. Find out what exists

1. Read the app's logging setup: which library, which format, where it writes.
2. If the app already runs on a host with EdgePacer, see whether LogPacer found its logs: `list_discovered_sources host_id=<id>` (CLI: `logpacer ops run list_discovered_sources --arg host_id=<id> --format json`). `get_discovered_source source_id=<id>` (CLI: `logpacer ops run get_discovered_source --arg source_id=<id> --format json`) shows the format, fields and parse coverage LogPacer found.

## 2. Destination

- **Containers:** write to stdout and stderr, not to files inside the container.
- **systemd services:** stdout and stderr go to the journal, which EdgePacer reads.
- **Files:** a stable path such as `/var/log/<app>/<app>.log`, rotated by rename (logrotate's default) rather than truncated in place.
- **Windows:** a Windows Event Log channel or a file.

When EdgePacer does not find a file, the human adds its path to the host's scan paths on the host's configuration page (`human_actions` on `get_host`). Agents cannot change host configuration.

## 3. Shape of each entry

For a new logger, or when the human asks for changes:

- Start every entry the same way, with a timestamp that carries its offset (RFC 3339, such as `2026-10-16T12:00:00.123Z`) and a level. A stack trace may span several lines; a consistent start is how each entry's first line is recognised.
- Keep the message text stable and put variable values in key=value pairs (or JSON fields) rather than mid-sentence.

## 4. Trace and span ids

Instrument the app first (`logpacer-instrument-otlp`); the ids come from the active OpenTelemetry span. Then follow the reference for the app's language:

- `references/node.md`
- `references/python.md`
- `references/java.md`
- `references/dotnet.md`
- `references/go.md`
- `references/ruby.md`
- `references/php.md`

## 5. Verify

Deploy the change and make the app handle a request that is traced.

1. **A recent trace id.** `discover_sources` with `signals: ["traces"]` (CLI: `logpacer sources --signals traces --format json`) gives the trace source's `query_target`. `search_logs` on it with its `filter`, `since: "15m"` and `limit: 1` returns a span to take the trace id from (CLI: `logpacer --repo <repo_id> search --filter-json '<filter>' --since 15m --limit 1 --format json`). `get_schema` with `resolve: "trace_id"` names the field when it is not obvious (CLI: `logpacer --repo <repo_id> schema --format json`).
2. **The app's log source.** `discover_sources filter=<app>` (CLI: `logpacer sources --filter <app> --format json`) gives its `query_target`.
3. **Correlate.** `correlate` with `anchors: [{"trace_id": "<id>"}]`, `sources: [{"repo_id": <log repo>, "filter": <its filter>}]`, a fixed RFC 3339 `window` around the request and `relations: ["trace_logs"]` (CLI: `logpacer correlate --json @correlation.json --format json`, same body). A matched log row proves the logs carry the id and LogPacer reads it.

No match:

- `get_schema` on the log repo with `fields: ["trace_id"]` (CLI: `logpacer --repo <id> schema --fields trace_id --format json`) shows whether the field is parsed yet.
- `get_discovered_source` (CLI: `logpacer ops run get_discovered_source --arg source_id=<id>`) shows the source's `findings`. LogPacer asks for a fresh sample when a collected source's shape changes; check again later before changing anything else.
- Look at a raw line with `search_logs` (CLI: `logpacer --repo <id> search --since 15m --limit 3 --format json`) and confirm the ids are present and spelled as rule 3 says.
