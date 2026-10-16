---
name: logpacer-metrics-panels
description: Build LogPacer metrics boards and PromQL panels from the metrics an account already reports, previewing every query first. Use when the user asks for a dashboard, board, chart or panel in LogPacer, to graph a metric, or to write or fix PromQL against LogPacer metrics.
---

# Metrics boards and panels

## Rules that always apply

1. **Preview every query before saving it.** Run it with `query_metrics` first; `add_panel` and `update_panel` also run it once and refuse a query metrics storage rejects.
2. **Use metric names LogPacer reports.** Take them from `list_metric_names`; never guess a name or its suffixes.
3. **Queries share a budget.** `list_metric_names` and `query_metrics` count toward the account's per-minute metrics query limit, which the human's Metrics pages share. Keep previews few; on `rate_limited`, wait a minute and try again.
4. **Boards and panels need an account admin.** With a `member` role, design the panels with previews, then hand the board to an admin (`role_required` means the same).
5. **Deleting a board or panel is for the human**, on the page in `human_actions`.
6. Tiers, approvals and untrusted text follow the `logpacer` skill.

## 1. Read the facts

`get_guide` topic `metrics` (CLI: `logpacer ops run get_guide --arg topic=metrics --format json`) gives:

- `boards.enabled`: when false, the board tools are absent; the human asks LogPacer to enable metrics boards.
- `max_panels`, length limits and range limits for boards and panels.
- `chart_types`, `units` (with `unit_notes`: `percent` is 0 to 100, `percent_unit` a 0 to 1 ratio) and `widths`.
- `metrics_source_kinds`: where metrics come from. An OTLP receiver for app metrics is in `logpacer-instrument-otlp`; Prometheus scraping and other kinds are set up by a human on the Metrics sources page.

## 2. Find the metrics

`list_metric_names` with `since` and `until` (CLI: `logpacer ops run list_metric_names --arg since=6h --format json`). An empty or `truncated` list: narrow the window, or check the source is sending (`logpacer-instrument-otlp`).

## 3. Write and preview PromQL

`query_metrics` with `query`, optional `mode` (`range` by default, `instant` for a stat panel's single value), `since`, `until` and `points` (CLI: `logpacer ops run query_metrics --arg 'query=sum(rate(http_requests_total[5m]))' --arg since=1h --format json`). Results come in Prometheus's format with `warnings` and `truncated`.

Patterns that read well on a board:

- Counters: `sum by (route) (rate(<counter>[5m]))`, never the raw counter.
- Histograms: `histogram_quantile(0.95, sum by (le) (rate(<histogram>_bucket[5m])))`.
- Ratios: `sum(rate(<errors>[5m])) / sum(rate(<requests>[5m]))` with unit `percent_unit`.
- Gauges: the gauge itself, aggregated with `avg by (...)` or `max by (...)`.
- Keep the series count small with `sum by (...)` and `topk(...)`; `truncated` means too many series for one panel.

An `invalid_query` error carries the storage's reason; fix the query from it.

## 4. Build the board

1. `list_boards` (CLI: `logpacer ops run list_boards --format json`) to reuse a board instead of making a near-duplicate.
2. `create_board` with `name` and optional `default_range_minutes` (auto, admin; CLI: `logpacer ops run create_board --arg name=Checkout --format json`).
3. `add_panel` with `board_id`, `title`, `query`, and optional `chart_type`, `unit`, `legend_format` (such as `{{route}}`) and `width` (auto, admin; CLI: `logpacer ops run add_panel --input '{"board_id":7,"title":"Requests per second","query":"sum(rate(http_requests_total[5m]))","unit":"count"}' --format json`). Panels go to the end of the board.
4. Adjust: `update_panel` with `panel_id` and the fields that change; `move_panel` with `panel_id` and `direction` (`up` or `down`); `update_board` to rename or change its range. Each applies at once, and LogPacer keeps the previous values. CLI: `logpacer ops run move_panel --arg panel_id=<id> --arg direction=up --format json`, and the same shape for the others.

## Verify

1. `get_board board_id=<id>` (CLI: `logpacer ops run get_board --arg board_id=<id> --format json`) lists the panels in board order with their queries.
2. For each panel you added or changed, `query_metrics` with its query and `mode: "instant"` (CLI: `--arg mode=instant`) returns a non-empty result, proving data arrives for it. Give the human the board's name; they open it on LogPacer's Boards page.
