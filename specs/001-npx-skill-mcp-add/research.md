# Research: Use npx skill/mcp add Commands

**Date**: 2026-03-24
**Branch**: `001-npx-skill-mcp-add`

## R1: MCP Server Installation CLI

### Decision: Use `npx add-mcp` (package: `add-mcp@1.5.1`)

**Rationale**: `add-mcp` by Neon is the standard tool for installing MCP servers across coding agents. It explicitly supports `mcporter` as a target agent, which is what OpenClaw uses for MCP configuration.

**CLI Syntax**:

```bash
# General usage
npx add-mcp [options] <target>

# Key options
#   -a, --agent <agent>     Target agent (e.g., "mcporter")
#   -n, --name <name>       Server name
#   -t, --transport <type>  Transport type for remote servers (http, sse)
#   -g, --global            Install globally (user-level)
#   -y, --yes               Skip confirmation prompts
#   --header <header>       HTTP headers (repeatable)

# Stdio server (e.g., mcp-server-tron)
npx add-mcp -a mcporter -n mcp-server-tron -y @bankofai/mcp-server-tron@1.1.7

# Remote server (e.g., bankofai-recharge)
npx add-mcp -a mcporter -n bankofai-recharge -t http -y https://recharge.bankofai.io/mcp
```

**Alternatives considered**:
- `npx mcporter add` — mcporter CLI exists (v0.7.3) but requires Node 20+ and its `add` subcommand is undocumented
- Manual JSON manipulation (current approach) — works but fragile, requires Python 3

**Open question**: `add-mcp` does not have a built-in flag for environment variables (like `TRONGRID_API_KEY`, `PRIVATE_KEY`). Environment variables may need to be:
1. Set before running the command and auto-detected
2. Manually added to the config file after `add-mcp` creates the entry
3. Passed via a mechanism not documented in `--help`

**Mitigation**: After `npx add-mcp` creates the server entry, use a lightweight JSON merge (Node.js one-liner or `node -e`) to add env vars to the generated config entry. This eliminates the Python dependency while still handling env vars.

## R2: Skills Installation CLI

### Decision: Use `npx skills add` (package: `skills@1.4.6`)

**Rationale**: The `skills` package (by Vercel Labs) is the standard open agent skills ecosystem. It supports OpenClaw as a target agent (listed in keywords: `openclaw`). The deprecated `add-skill` package redirects to `npx skills add`.

**CLI Syntax**:

```bash
# General usage
npx skills add <package> [options]

# Key options
#   -g, --global              Install globally (user-level)
#   -a, --agent <agents>      Target agents (e.g., "openclaw")
#   -s, --skill <skills>      Specific skill names to install (use '*' for all)
#   -y, --yes                 Skip confirmation prompts
#   --copy                    Copy files instead of symlinking
#   --all                     Shorthand for --skill '*' --agent '*' -y

# From GitHub repo
npx skills add BofAI/skills -g -a openclaw -s sunswap -y
npx skills add BofAI/skills -g -a openclaw -s tronscan-skill -y

# Install all skills from repo
npx skills add BofAI/skills -g -a openclaw --all

# Other subcommands
npx skills list -g                # List installed skills
npx skills remove -g --all        # Remove all (for clean install)
```

**Alternatives considered**:
- Git clone + cp + npm install (current approach) — works but heavy, requires git, manual SKILL.md discovery
- `npx add-skill` — deprecated, redirects to `npx skills add`

**Key behaviors**:
- Accepts GitHub `owner/repo` format as package source
- Supports `-s` flag to select specific skills from a multi-skill repo
- Has `remove` subcommand useful for clean install mode
- Has `--copy` flag (vs symlink) — may be needed for robustness

## R3: Environment Variable Handling for MCP Servers

### Decision: Use Node.js one-liner for env var injection post-add

**Rationale**: `add-mcp` creates the server config entry but doesn't support env var injection. After adding the server, a Node.js one-liner can merge env vars into the JSON config, replacing the current Python-based approach.

```bash
# Example: Add env vars to an existing mcporter.json entry
node -e "
const fs = require('fs');
const f = '$HOME/.mcporter/mcporter.json';
const d = JSON.parse(fs.readFileSync(f, 'utf8'));
if (d.mcpServers && d.mcpServers['mcp-server-tron']) {
  d.mcpServers['mcp-server-tron'].env = { ...d.mcpServers['mcp-server-tron'].env, TRONGRID_API_KEY: '$VALUE' };
  fs.writeFileSync(f, JSON.stringify(d, null, 2));
}
"
```

**This eliminates the Python 3 dependency** — Node.js is already a prerequisite.

## R4: Clean Install Mode

### Decision: Use `npx skills remove --all` and manual JSON reset for MCP

**Rationale**: The `skills` CLI has a `remove` subcommand with `--all` flag. For MCP, `add-mcp` doesn't have a `remove` command, so the clean install MCP reset can be done with a Node.js one-liner (reset `mcpServers` to `{}`).

```bash
# Clean skills
npx skills remove -g -a openclaw --all -y

# Clean MCP entries (Node.js one-liner replacing Python)
node -e "
const fs = require('fs');
const f = '$HOME/.mcporter/mcporter.json';
const d = fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : {};
d.mcpServers = {};
fs.writeFileSync(f, JSON.stringify(d, null, 2));
"
```

## R5: Python 3 Dependency Elimination

### Decision: Python 3 is no longer required

**Rationale**: All current Python usage is for JSON manipulation:
1. `write_server_config()` — replaced by `npx add-mcp` + Node.js env var merge
2. `clear_all_mcp_entries()` — replaced by Node.js one-liner
3. `json_string_or_null()` — replaced by Node.js one-liner
4. `configure_bankofai_api_key()` — Python JSON read/write, replaced by Node.js
5. x402-payment config check/write — replaced by Node.js

All can use `node -e` since Node.js v18+ is already a prerequisite.

## R6: Install Location for Skills

### Decision: Research needed on `npx skills add` default behavior

The current installer lets users choose between user-level (`~/.openclaw/skills/`), workspace-level (`.openclaw/skills/`), or custom paths. The `npx skills add` command has `-g` (global) vs project-level distinction.

- `-g` flag → user-level (global) — maps to `~/.openclaw/skills/`
- No `-g` → project-level — maps to `.openclaw/skills/`
- Custom path may not be directly supported by `npx skills add`

**Mitigation**: Default to `-g` (user-level, recommended), offer workspace-level as alternative. Custom path may require `--copy` to a specific location or a post-install move.
