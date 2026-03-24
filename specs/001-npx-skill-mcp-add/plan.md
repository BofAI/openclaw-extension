# Implementation Plan: Use npx skill/mcp add Commands

**Branch**: `001-npx-skill-mcp-add` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-npx-skill-mcp-add/spec.md`

## Summary

Replace the custom Python-based JSON manipulation and git-clone-and-copy approach in `install.sh` with standard CLI tools: `npx add-mcp` (v1.5.1) for MCP server registration and `npx skills add` (v1.4.6) for skill installation. This eliminates the Python 3 dependency, reduces code complexity (~300 lines of Python/bash removed), and aligns with the open agent skills ecosystem.

## Technical Context

**Language/Version**: Bash (POSIX-compatible with bashisms)
**Primary Dependencies**: `add-mcp@1.5.1` (via npx), `skills@1.4.6` (via npx), Node.js v18+
**Storage**: JSON config files (`~/.mcporter/mcporter.json`, `~/.x402-config.json`, `~/.mcporter/bankofai-config.json`)
**Testing**: `bash -n install.sh` (syntax), `shellcheck install.sh` (lint), manual end-to-end test
**Target Platform**: Linux/macOS with bash
**Project Type**: CLI installer (single bash script)
**Performance Goals**: N/A (one-time installer)
**Constraints**: Must work when piped from curl (`curl ... | bash`), interactive I/O via `/dev/tty`
**Scale/Scope**: Single file (`install.sh`, ~1100 lines → ~700 lines after refactor)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is unconfigured (template placeholders only). No gates apply. **PASS**.

**Post-Phase 1 re-check**: Still PASS — no constitution constraints defined.

## Project Structure

### Documentation (this feature)

```text
specs/001-npx-skill-mcp-add/
├── plan.md              # This file
├── research.md          # Phase 0 output — CLI research findings
├── data-model.md        # Phase 1 output — config file schemas
├── quickstart.md        # Phase 1 output — before/after examples
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
install.sh               # Single entry point — all changes in this file
```

**Structure Decision**: This is a single-file project. All changes are in `install.sh` at the repository root. No new files or directories are created in the source code.

## Implementation Approach

### Phase 1: Replace MCP Server Installation (FR-001, FR-004, FR-007)

**What changes**:
- Remove `write_server_config()` function (lines 122-187) — Python-based JSON writer
- Remove `json_string_or_null()` function (lines 211-218) — Python JSON escaping
- Remove `clear_all_mcp_entries()` function (lines 220-243) — Python JSON reset
- Replace MCP server case statements (lines 854-961) to use `npx add-mcp`

**New MCP installation flow**:

```bash
# For stdio servers (mcp-server-tron, bnbchain-mcp):
npx -y add-mcp -a mcporter -n "$SERVER_ID" -y "$PACKAGE_NAME"

# For remote servers (bankofai-recharge):
npx -y add-mcp -a mcporter -n "$SERVER_ID" -t http -y "$REMOTE_URL"

# For env var injection (post add-mcp):
node -e "
  const fs=require('fs'), f=process.env.MCP_FILE;
  const d=JSON.parse(fs.readFileSync(f,'utf8'));
  d.mcpServers['$SERVER_ID'].env={...d.mcpServers['$SERVER_ID'].env,...JSON.parse(process.env.ENV_JSON)};
  fs.writeFileSync(f,JSON.stringify(d,null,2));
"
```

**Server-specific details**:

| Server | add-mcp target | Env vars needed |
|--------|---------------|-----------------|
| mcp-server-tron | `@bankofai/mcp-server-tron@1.1.7` | `TRONGRID_API_KEY` (optional) |
| bnbchain-mcp | `@bnb-chain/mcp@latest` | `PRIVATE_KEY`, `LOG_LEVEL` (optional) |
| bankofai-recharge | `https://recharge.bankofai.io/mcp` | None |

### Phase 2: Replace Skills Installation (FR-002, FR-005, FR-008)

**What changes**:
- Remove `clone_skills_repo()` function (lines 537-548) — git clone logic
- Remove `copy_skill()` function (lines 676-801) — file copy + npm install
- Remove `select_install_target()` function (lines 551-583) — path selection
- Remove `pretty_skill_name()` function (lines 586-592)
- Remove skill discovery loop (lines 977-1005) — SKILL.md scanning
- Replace with `npx skills add` calls

**New skills installation flow**:

```bash
# Install individual skill from BofAI/skills repo:
npx -y skills add BofAI/skills -s "$SKILL_ID" -a openclaw -y [-g]

# For clean install — remove all first:
npx -y skills remove -a openclaw --all -y [-g]
```

**Install location mapping**:
- User-level (recommended) → `-g` flag (global)
- Workspace-level → no `-g` flag (project-level)
- Custom path → not directly supported; use `--copy` + manual move, or drop custom path option

### Phase 3: Replace Python JSON Helpers with Node.js (FR-003, FR-007)

**What changes**:
- Remove `PYTHON_CMD` detection and Python 3 prerequisite check (lines 97-105)
- Replace all inline Python with `node -e` one-liners:

| Current Python usage | Replacement |
|---------------------|-------------|
| `write_server_config()` | `npx add-mcp` + `node -e` env merge |
| `clear_all_mcp_entries()` | `node -e` JSON reset |
| `json_string_or_null()` | `node -e 'JSON.stringify()'` |
| bankofai-config.json read/write | `node -e` JSON read/write |
| x402-config.json read/write | `node -e` JSON read/write |
| x402 config existence check | `node -e` JSON parse + check |

### Phase 4: Clean Install Mode Update (FR-006)

**What changes**:
- `clear_all_mcp_entries()` → `node -e` to reset `mcpServers` in mcporter.json
- `clear_all_skills_under_dir()` → `npx -y skills remove -a openclaw --all -y -g` (and without `-g` for workspace)
- Keep all other clean install logic (confirmation prompts, x402/bankofai config deletion)

### Phase 5: Update Prerequisites and Cleanup (FR-009, FR-010)

**What changes**:
- Remove Python 3 from `check_env()` prerequisites
- Remove `TEMP_DIR`, `TMPFILES`, `mktempfile()`, and temp file cleanup logic
- Simplify `cleanup()` trap (no more temp dirs to clean)
- Update error handling: wrap `npx add-mcp` and `npx skills add` calls in conditional blocks with error messages
- Ensure all npx commands work with `/dev/tty` for pipe-install scenario

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `add-mcp` doesn't write expected mcporter.json format | Medium | High | Test locally first; fall back to Node.js JSON writer if needed |
| `npx skills add` doesn't support OpenClaw agent properly | Medium | High | Test with `-a openclaw`; fall back to `-a claude-code` or `--copy` |
| Env var injection after add-mcp creates race condition | Low | Medium | Sequential execution, verify file exists before merge |
| Custom install path no longer supported | Low | Low | Document in release notes; offer global vs project-level only |
| npx download overhead slows installation | Low | Low | Users already accept npx download time for agent-wallet |
