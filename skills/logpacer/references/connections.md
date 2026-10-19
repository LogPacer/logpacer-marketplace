# Connecting to other LogPacer deployments

The public plugin connects to `https://app.logpacer.com/mcp` by default. You can also connect to another LogPacer deployment, such as a staging environment or a local development server. Use the deployment URL supplied by the user; the examples below use `https://logpacer.example.com` as a placeholder. MCP URLs end in `/mcp`.

Give additional connections distinct names, such as `logpacer-staging` or `logpacer-dev`. Each connection needs its own sign-in and account selection. A successful login does not imply that agent changes are enabled: check that connection's `get_account_overview` before other operations.

## Codex

Install the plugin once to get its skills and the production connection. Add another MCP server through Codex configuration; editing an installed plugin's cached files is unnecessary and updates can overwrite those edits. Codex does not expand Claude's `${user_config.*}` settings, and this plugin's Codex connection does not use `LOGPACER_BASE_URL`.

### Available in one project

Add this table to the project's `.codex/config.toml`, preserving existing settings:

```toml
[mcp_servers.logpacer-staging]
url = "https://logpacer.example.com/mcp"
```

Codex loads project configuration only for trusted projects. From that project directory, verify the resolved URL and sign in:

```bash
codex mcp get logpacer-staging
codex mcp login logpacer-staging
```

Start a new Codex session after changing the configuration so the connection's tools are available. The bundled production connection remains available too; a new server entry does not replace it.

### Available across projects

To add the connection to your user configuration instead:

```bash
codex mcp add logpacer-staging --url https://logpacer.example.com/mcp
codex mcp login logpacer-staging
```

`codex mcp add` writes user configuration even when run inside a project. Use the project file above when the connection should be scoped to that project.

### Choose a project default

An MCP entry makes a connection available; a project instruction tells the agent when to use it. Add a rule like this to the project's `AGENTS.md`, adapted to the user's actual connection names and intended default:

> Use `logpacer-staging` for LogPacer tasks in this project unless the task names another deployment. Use the bundled production connection when the task explicitly targets production. Before other LogPacer operations, read the selected connection's account overview. Keep resource IDs and approval follow-ups on the connection that produced them.

This permits explicit tasks against either environment and comparisons across both. If a requested target is unavailable, configure or authenticate it rather than substituting another connection.

### Verify the setup

Check `codex mcp get logpacer-staging` from inside the project. For a project-only entry, check from an unrelated project too: the entry should be absent unless a user-level entry also defines it. In a new agent session, ask it to read the staging account overview and confirm the expected account. If you also use production, check that connection separately and label both results.

Connection setup does not deploy LogPacer, enable agent changes or grant write access. Follow the account overview's next step when those capabilities are unavailable.

Sources: [Codex MCP configuration and OAuth](https://learn.chatgpt.com/docs/extend/mcp?surface=cli), [Claude plugin settings compatibility](https://developers.openai.com/plugins/guides/submit-claude-plugin#replace-claude-userconfig).

## Other clients

- **Claude Code:** this plugin reads `LOGPACER_BASE_URL`, defaulting to production. For a session against another deployment, run `LOGPACER_BASE_URL=https://logpacer.example.com claude`. Use a base URL without `/mcp` or a trailing slash. This changes the bundled connection's destination; to use both deployments in one session, add a separately named MCP server through Claude Code's configuration. Use `/mcp` to inspect connections and sign in.
- **Cursor and other MCP clients:** add a separately named server with the full MCP URL in the client's configuration. The shared skills work with each connection; choose the scope and sign-in flow supported by that client.
- **CLI:** sign in to the intended deployment with `logpacer auth login --base-url https://logpacer.example.com`, then check `logpacer auth status`. Check the CLI's current profile and URL options before switching between deployments; a login in one agent does not configure another.
