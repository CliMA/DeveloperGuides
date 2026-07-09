# Buildkite Access via MCP

This guide sets up authenticated access to CliMA's Buildkite (job logs, build and job status, artifacts) for AI coding tools, via the official [Buildkite MCP server](https://buildkite.com/docs/apis/mcp-server).
Anonymous access to `buildkite.com/clima` shows build status only; job-level logs require an authenticated API token.
Steps 1-4 apply to any tool that supports the Model Context Protocol (MCP); client registration is shown for Claude Code in its own section.
Pairs with [ci_triage.md](ci_triage.md): with this set up, an agent can read the failing job's log itself instead of asking you to paste it.

## 1. Authorize with the clima organization (SSO)

The clima organization requires SSO.
Visit https://buildkite.com/sso/clima and authenticate with your Caltech identity.
Afterwards, https://buildkite.com/clima shows pipelines while you are signed in.
Without this step, no API token on your account can see the organization.

## 2. Create an API token

At https://buildkite.com/user/api-access-tokens, create a token (the value starts with `bkua_`):

- **Organization Access**: check `clima`. This setting is separate from scopes; without it the API returns "No organization found".
- **Scopes** (read-only; do not grant write scopes):
  - `read_builds`: build, job, and annotation status
  - `read_build_logs`: job logs
  - `read_pipelines`, `read_user`: required by most MCP tools
  - Optional: `read_artifacts` (download CI artifacts), `read_organizations` (organization discovery), `read_agents`
- Set an expiry.

## 3. Install the MCP server

macOS:

```sh
brew install buildkite/buildkite/buildkite-mcp-server
```

Linux (no docker required):

```sh
mkdir -p ~/bin
gh release download --repo buildkite/buildkite-mcp-server \
    --pattern 'buildkite-mcp-server_Linux_x86_64.tar.gz' -O - \
    | tar xz -C ~/bin buildkite-mcp-server
~/bin/buildkite-mcp-server --version   # assumes ~/bin is on PATH for the later steps
```

## 4. Store the token outside the client configuration

Keep the secret in a mode-600 file and launch the server through a wrapper, so the token does not appear in any client configuration file:

```sh
(umask 077; mkdir -p ~/.config/buildkite; printf '%s\n' 'bkua_XXXX' > ~/.config/buildkite/api-token)

cat > ~/bin/buildkite-mcp-wrapper <<'EOF'
#!/bin/bash
TOKEN_FILE="$HOME/.config/buildkite/api-token"
[ -r "$TOKEN_FILE" ] || { echo "missing $TOKEN_FILE" >&2; exit 1; }
BUILDKITE_API_TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE") exec buildkite-mcp-server stdio
EOF
chmod +x ~/bin/buildkite-mcp-wrapper
```

Any MCP client can now run `~/bin/buildkite-mcp-wrapper` as a stdio MCP server; register it per that client's MCP configuration.

## 5. Register with Claude Code

```sh
claude mcp add buildkite -- ~/bin/buildkite-mcp-wrapper
claude mcp list   # should show: buildkite ... - ✔ Connected
```

To test inside a session, ask the agent to run the `access_token` Buildkite tool, which reports the token's scopes, or to fetch a recent build from `clima/climaatmos-ci`.

## Troubleshooting

- **"No organization found" or an empty organization list**: the token's Organization Access box for `clima` is unchecked, or the SSO authorization (step 1) has not been done.
- **401 unauthorized after rotating the token**: the running MCP server still holds the old token (the wrapper reads the file at launch).
  Restart the MCP server; in Claude Code, run `/mcp` and reconnect the buildkite server, or restart the session.
- **403 on organization listing only**: the optional `read_organizations` scope is missing; per-build and log tools work without it.
- **Job state `broken`**: the job did not run (a conditional or dependency prevented it), which is different from `failed` (ran and exited non-zero).

## Self-correction

If this guide is discovered to be stale or missing a pattern, update it.
