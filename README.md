# LogPacer for coding agents

This repository is the LogPacer plugin for coding agents. LogPacer is in private beta.

The plugin gives your agent two things:

- **A connection to the LogPacer MCP server** at `https://app.logpacer.com/mcp`. Through it the agent reads your logs, metrics and traces and makes changes in your LogPacer account. A change that alters what is collected, analysed or stopped, or who is notified, waits for a person to approve it.
- **Skills** that teach the agent LogPacer's workflows. The skills hold the workflow; facts such as endpoints and install commands come live from LogPacer.

| Skill | Teaches |
|---|---|
| `logpacer` | Start here: connecting, approvals, roles and safety rules |
| `logpacer-install-edgepacer` | Installing EdgePacer on a host, in Docker or in Kubernetes |
| `logpacer-pick-sources` | Choosing, analyzing and collecting discovered sources, and Handling modes |
| `logpacer-instrument-otlp` | Sending an app's traces and metrics over OTLP, per language |
| `logpacer-logging-setup` | Logging so LogPacer collects the logs and links them to traces |
| `logpacer-metrics-panels` | Metrics boards and PromQL panels |
| `logpacer-monitors-alerts` | Cron monitors and notification destinations |
| `logpacer-investigate` | Searching, counting and correlating logs and traces |

## Install

### Claude Code

```
/plugin marketplace add LogPacer/logpacer-marketplace
/plugin install logpacer@logpacer
```

### Codex

```bash
codex plugin marketplace add LogPacer/logpacer-marketplace
codex plugin add logpacer@logpacer
```

### Cursor

Cursor installs plugins from the Cursor Marketplace or from a team marketplace. Until LogPacer is listed, Teams and Enterprise plans can import this repository as a team marketplace, or add it from the Cursor CLI:

```bash
cursor-agent plugin marketplace add https://github.com/LogPacer/logpacer-marketplace
```

On other plans, install the skills with `npx skills add` (below) and add the server to `.cursor/mcp.json`:

```json
{ "mcpServers": { "logpacer": { "url": "https://app.logpacer.com/mcp" } } }
```

### Antigravity

```bash
agy plugin install https://github.com/LogPacer/logpacer-marketplace
```

### Gemini CLI

```bash
gemini extensions install https://github.com/LogPacer/logpacer-marketplace
```

### Other agents

```bash
npx skills add LogPacer/logpacer-marketplace
```

This installs the skills only. Add the MCP server `https://app.logpacer.com/mcp` (Streamable HTTP) in your agent's MCP settings.

### Pi

Pi uses the skills together with the `logpacer` CLI.

```bash
npx skills add LogPacer/logpacer-marketplace
curl -fsS https://app.logpacer.com/install/cli | sh
logpacer auth login --base-url https://app.logpacer.com
```

The CLI installer is served by your LogPacer deployment at `/install/cli`.

## Sign in

Each agent signs in to LogPacer with OAuth the first time it uses the server. Your browser opens LogPacer's sign-in page, where you pick the account. In Claude Code, run `/mcp` if the sign-in does not start on its own.

Grant write access when LogPacer asks for it, or turn on Allow changes for the connection under Settings → API Credentials in LogPacer. The agent needs it to make changes, and changes that alter collection or notifications still wait for your approval.

## Developing locally

The shipped manifests always point at `https://app.logpacer.com/mcp`. To test against a local LogPacer, load the plugin from this checkout and add a separate dev server by hand; the override lives only in your local agent config. Replace `<port>` with your local LogPacer port.

Both servers offer the same tools. In Claude Code, disable `plugin:logpacer:logpacer` in `/mcp`; in other agents, tell the agent to use `logpacer-dev`, so tool calls do not reach production.

```bash
# Claude Code
claude mcp add --transport http logpacer-dev http://localhost:<port>/mcp
claude --plugin-dir .

# Codex
codex plugin marketplace add "$PWD"
codex plugin add logpacer@logpacer
codex mcp add logpacer-dev --url http://localhost:<port>/mcp

# Cursor: add logpacer-dev to .cursor/mcp.json with the local URL
cursor-agent --plugin-dir .

# Antigravity
agy plugin install "$PWD"
agy mcp add --type http logpacer-dev http://localhost:<port>/mcp

# Gemini CLI
gemini extensions link .
gemini mcp add --transport http logpacer-dev http://localhost:<port>/mcp
```

### Checks

```bash
ruby scripts/sync-versions --check
ruby scripts/check-skills
ruby -Itest -e 'Dir["test/*_test.rb"].sort.each { |f| require File.expand_path(f) }'
claude plugin validate --strict .
agy plugin validate .
```

CI runs all of these except `agy plugin validate`, which runs locally.

`.claude-plugin/plugin.json` holds the version. To release, bump it there and run `ruby scripts/sync-versions --fix` to copy it into every other manifest.

`scripts/check-skills` keeps each `SKILL.md` under 8,000 bytes, checks its frontmatter, and rejects internal names and hostnames anywhere under `skills/`.

### Layout

| File | Read by |
|---|---|
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.mcp.json` | Claude Code |
| `plugin.json`, `mcp.json` (Agent Plugins 1.0) | Codex and other Agent Plugins clients |
| `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | Codex (catalog and display details; older Codex versions read skills and MCP here too) |
| `.cursor-plugin/plugin.json`, `.cursor-plugin/marketplace.json` | Cursor |
| `.antigravity-plugin/plugin.json`, `mcp_config.json` | Antigravity |
| `gemini-extension.json`, `GEMINI.md` | Gemini CLI |
| `skills/` | every agent |

## License

MIT
