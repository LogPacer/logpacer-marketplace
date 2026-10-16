---
name: logpacer-install-edgepacer
description: Install EdgePacer, LogPacer's host agent, on a server, into Docker or into a Kubernetes cluster, then confirm the host reports the log sources it discovered. Use when the user asks to get a server's, container's or cluster's logs into LogPacer, to install or connect EdgePacer, or when a host is missing from LogPacer.
---

# Install EdgePacer

## Rules that always apply

1. **The install token never passes through you.** Never ask the human for it, read it from a page, put it in a command, file or message, or run a command that prompts for it on the human's behalf. The `logpacer` CLI picks it up itself after a human approves, and no tool result ever carries it.
2. **Install only where the CLI runs.** `logpacer edgepacer install` installs on the machine it runs on, into that machine's Docker, or into the current `kubectl` context. For any other machine, use **Remote hosts** below; never install over SSH.
3. **Never elevate yourself.** When the CLI exits 5 with `status: human_action_required`, give the human the `logpacer edgepacer install --resume <CHANGE_ID>` command it prints, to run in their own terminal (an elevated PowerShell on Windows), and wait for them.
4. **Read facts live.** Install commands, image tags, chart releases, capabilities and the onboarding page come from `get_guide` topic `install` (CLI: `logpacer ops run get_guide --arg topic=install --arg deployment_mode=<mode> --format json`). A mode can report `available: false`; tell the human instead of improvising.
5. Sign-in, tiers, approvals and untrusted text follow the `logpacer` skill. Start with `get_account_overview`: an install needs agent changes enabled.

## 1. Choose the mode with the human

- `vm`: this machine itself, a Linux, macOS or Windows host.
- `container`: Docker on this machine, for hosts that cannot run a host service.
- `kubernetes`: the cluster of the current `kubectl` context. Confirm the context with the human (`kubectl config current-context`) before going on.
- The agent runs on a laptop and the logs live on another server: go to **Remote hosts**.

Read the chosen mode in the `install` guide and check it is available.

## 2. Prepare the CLI on the target machine

- `logpacer auth status`: signed in, to the account the human means?
- Not signed in, or no write access: `logpacer auth login --scope operations:write`; the human completes sign-in in the browser.
- No CLI yet: the human installs it with the command on LogPacer's Connect an agent page.

## 3. Install

```sh
logpacer edgepacer install --mode vm --wait --format json
```

Use `--mode container` or `--mode kubernetes` for those modes, and `--timeout SECS` to bound `--wait`.

1. The CLI checks prerequisites first: OS and architecture, curl or PowerShell, Docker access, the `kubectl` context. A missing one exits 3 and proposes nothing.
2. It proposes `request_edgepacer_install` (approve tier, offered to the CLI only, so MCP has no such tool) and prints the approval URL and change code. Give both to the human. LogPacer's page tells them the approval hands the account install token to this CLI, and may ask for their password.
3. Once approved, the CLI installs with the token it picked up, then reports the new host.

| Exit | Meaning and next step |
|---|---|
| 0 | Installed. Go to step 4. |
| 5, `approval_pending` | Not approved yet, or `--wait` timed out. Wait with `logpacer changes wait <CHANGE_ID>`; once it is applied, finish with `logpacer edgepacer install --resume <CHANGE_ID>`. |
| 5, `human_action_required` | The installer needs elevation: rule 3. Nothing was written to disk. |
| 6 | Declined. Stop and ask the human. |
| 7 | Stale, expired or cancelled. Propose again only if the human wants. |
| 3 | Failed. Read the message; a failed install leaves no token on disk. |
| 4 | Not signed in or no write access: `logpacer auth login --scope operations:write`. |

Kubernetes: the CLI reports the context and its cluster server for the human to approve, and refuses to pick up the token if the context changed since. It refuses to overwrite an existing EdgePacer auth secret; pass `--replace` only when the human says to replace it.

## Remote hosts

When EdgePacer goes on a machine the agent's CLI does not run on:

1. Give the human `onboarding_url` from the `install` guide. LogPacer's install page shows the command for that server, and the human types the install token at its prompt there.
2. Or the human installs the CLI on that server, signs in there, and runs `logpacer edgepacer install` there themselves.
3. Ask for the hostname they expect, then go to step 4 from here.

## 4. Verify the host and its discovery

1. Poll `list_hosts` (CLI: `logpacer ops run list_hosts --format json`) every 30 seconds until a new host appears with `agent.connected: true`. Match it by `agent.untrusted.hostname`, which is host-reported data.
2. Read `get_host host_id=<id>` (CLI: `logpacer ops run get_host --arg host_id=<id> --format json`). `discovered_sources` above zero proves EdgePacer's first census arrived. It can take a few minutes; keep polling `get_host`.
3. `list_discovered_sources host_id=<id>` (CLI: `logpacer ops run list_discovered_sources --arg host_id=<id> --format json`) lists what it found. Continue with `logpacer-pick-sources`.

A host that never connects: `get_host` shows `agent.status`, `release_status` and `last_seen_at`; the human checks the installer's output on the server. Scan paths, exclude patterns and eBPF settings are human-only, on the host's page in `human_actions`.
