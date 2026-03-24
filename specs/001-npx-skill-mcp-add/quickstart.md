# Quickstart: npx skill/mcp add Commands

## Prerequisites

- Node.js v18+
- Git
- OpenClaw installed (`~/.openclaw` exists)

## What Changes

### Before (current)
```bash
# MCP: Python script writes JSON to mcporter.json
write_server_config "mcp-server-tron" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"

# Skills: Git clone + copy + npm install
git clone --depth 1 -b v1.5.0 https://github.com/BofAI/skills.git /tmp/...
cp -r /tmp/.../sunswap ~/.openclaw/skills/
cd ~/.openclaw/skills/sunswap && npm install
```

### After (new)
```bash
# MCP: npx add-mcp writes to mcporter.json
npx add-mcp -a mcporter -n mcp-server-tron -y @bankofai/mcp-server-tron@1.1.7

# Skills: npx skills add handles clone + install
npx skills add BofAI/skills -g -a openclaw -s sunswap -y
```

## Testing the Changes

```bash
# Validate bash syntax
bash -n install.sh

# Run installer directly
./install.sh

# Run in pipe mode (simulates curl | bash)
cat install.sh | bash

# Verify MCP config was written
cat ~/.mcporter/mcporter.json

# Verify skills installed
npx skills list -g
```

## Key Decisions

1. **`add-mcp` for MCP servers** — standard tool, supports mcporter agent
2. **`skills` for skill installation** — Vercel Labs ecosystem, supports OpenClaw
3. **Node.js for JSON ops** — replaces Python, uses already-required Node.js
4. **Python 3 no longer required** — removed from prerequisites
