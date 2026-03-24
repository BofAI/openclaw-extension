# Tasks: Use npx skill/mcp add Commands in Installer

**Input**: Design documents from `/specs/001-npx-skill-mcp-add/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Not explicitly requested. No test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Remove dead code and Python dependency, prepare install.sh for new CLI-based approach

- [x] T001 Remove Python 3 prerequisite check from `check_env()` function in install.sh (lines 97-105)
- [x] T002 Remove `PYTHON_CMD` variable usage and Python interpreter detection in install.sh
- [x] T003 [P] Remove `write_server_config()` function (lines 122-187) in install.sh
- [x] T004 [P] Remove `json_string_or_null()` function (lines 211-218) in install.sh
- [x] T005 [P] Remove `clear_all_mcp_entries()` function (lines 220-243) in install.sh
- [x] T006 [P] Remove `clone_skills_repo()` function (lines 537-548) in install.sh
- [x] T007 [P] Remove `copy_skill()` function (lines 676-801) in install.sh
- [x] T008 [P] Remove `select_install_target()` function (lines 551-583) in install.sh
- [x] T009 [P] Remove `pretty_skill_name()` function (lines 586-592) in install.sh
- [x] T010 Remove `TEMP_DIR`, `TMPFILES`, `mktempfile()` variables and temp file cleanup logic in install.sh
- [x] T011 Simplify `cleanup()` trap function — remove temp dir/file cleanup, keep `tput cnorm` in install.sh
- [x] T012 Remove `GITHUB_REPO`, `GITHUB_BRANCH` variables from Configuration section in install.sh

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add Node.js-based JSON helper to replace Python JSON manipulation

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T013 Create `node_json_merge()` bash helper function in install.sh that merges env vars into a mcporter.json server entry using `node -e` (replaces `write_server_config` for env var injection after `npx add-mcp`)
- [x] T014 Create `node_json_write()` bash helper function in install.sh that writes a JSON object to a file using `node -e` (replaces Python JSON write for bankofai-config.json, x402-config.json)
- [x] T015 Create `node_json_read()` bash helper function in install.sh that reads a JSON key from a file using `node -e` and prints to stdout (replaces Python JSON read for config existence checks)
- [x] T016 Create `node_json_reset_mcp()` bash helper function in install.sh that resets `mcpServers` to `{}` in mcporter.json using `node -e` (replaces `clear_all_mcp_entries`)

**Checkpoint**: Foundation ready — Node.js JSON helpers available, dead Python code removed

---

## Phase 3: User Story 1 — MCP Server Installation via npx add-mcp (Priority: P1) MVP

**Goal**: Replace Python-based `write_server_config` with `npx add-mcp` for all 3 MCP servers

**Independent Test**: Run `./install.sh`, select MCP servers, verify `~/.mcporter/mcporter.json` contains correct entries

### Implementation for User Story 1

- [x] T017 [US1] Replace mcp-server-tron case branch (lines 855-873) to call `npx -y add-mcp -a mcporter -n mcp-server-tron -y @bankofai/mcp-server-tron@1.1.7` followed by `node_json_merge` for `TRONGRID_API_KEY` env var in install.sh
- [x] T018 [US1] Replace bnbchain-mcp case branch (lines 876-949) to call `npx -y add-mcp -a mcporter -n bnbchain-mcp -y @bnb-chain/mcp@latest` followed by `node_json_merge` for `PRIVATE_KEY` and `LOG_LEVEL` env vars (config-file mode) or no env merge (env-var mode) in install.sh
- [x] T019 [US1] Replace bankofai-recharge case branch (lines 952-960) to call `npx -y add-mcp -a mcporter -n bankofai-recharge -t http -y https://recharge.bankofai.io/mcp` in install.sh
- [x] T020 [US1] Update clean install `run_clean_install()` to use `node_json_reset_mcp` instead of `clear_all_mcp_entries()` in install.sh
- [x] T021 [US1] Wrap each `npx add-mcp` call in error handling: if command fails, print error message and `continue` to next server in install.sh
- [x] T022 [US1] Validate bash syntax with `bash -n install.sh` after MCP changes

**Checkpoint**: MCP server installation works end-to-end via `npx add-mcp`. Skills still use old approach.

---

## Phase 4: User Story 2 — Skills Installation via npx skills add (Priority: P1)

**Goal**: Replace git-clone-and-copy with `npx skills add` for all 5 skills

**Independent Test**: Run `./install.sh`, select skills, verify skills appear in `npx skills list -g`

### Implementation for User Story 2

- [x] T023 [US2] Replace Step 2 skills section (lines 968-1028) — remove git clone, skill discovery loop, and replace with static `SKILL_OPTIONS` array and `npx -y skills add BofAI/skills -s "$SKILL_ID" -a openclaw -y` per selected skill in install.sh
- [x] T024 [US2] Replace install location selection: offer "1) User-level (global) [Recommended]" and "2) Workspace-level (project)" mapping to `-g` flag vs no flag for `npx skills add` in install.sh
- [x] T025 [US2] Preserve post-install configuration triggers: after each `npx skills add` call, check `$SKILL_ID` and run `configure_bankofai_api_key` (recharge-skill), `configure_tronscan_api_key` (tronscan-skill), x402 config prompt (x402-payment), sunperp guidance (sunperp) in install.sh
- [x] T026 [US2] Update clean install `run_clean_install()` to call `npx -y skills remove -a openclaw --all -y -g` and `npx -y skills remove -a openclaw --all -y` instead of `clear_all_skills_under_dir()` in install.sh
- [x] T027 [US2] Wrap each `npx skills add` call in error handling: if command fails, print error and `continue` to next skill in install.sh
- [x] T028 [US2] Update `INSTALLED_SKILLS` tracking to use skill ID from the static array instead of `pretty_skill_name` in install.sh
- [x] T029 [US2] Validate bash syntax with `bash -n install.sh` after skills changes

**Checkpoint**: Skills installation works end-to-end via `npx skills add`. Both MCP and skills use new CLI approach.

---

## Phase 5: User Story 3 — Configuration Preservation (Priority: P2)

**Goal**: Migrate all Python-based config read/write to Node.js helpers while preserving all prompts and file outputs

**Independent Test**: Run installer, provide config values, verify `~/.x402-config.json`, `~/.mcporter/bankofai-config.json` contain correct data with correct permissions

### Implementation for User Story 3

- [x] T030 [US3] Rewrite `configure_bankofai_api_key()` to use `node_json_read` for checking existing key and `node_json_write` for writing bankofai-config.json, replacing all inline Python in install.sh
- [x] T031 [US3] Rewrite x402-payment Gasfree config block (previously inside `copy_skill`) to use `node_json_read` for checking existing credentials and `node_json_write` for writing `~/.x402-config.json`, replacing all inline Python in install.sh
- [x] T032 [US3] Move x402-payment and other skill-specific config prompts into a new `configure_skill()` function that runs after `npx skills add` based on skill ID in install.sh
- [x] T033 [US3] Verify `chmod 600` is still applied to `~/.x402-config.json` and `~/.mcporter/bankofai-config.json` after Node.js writes in install.sh
- [x] T034 [US3] Validate bash syntax with `bash -n install.sh` after config changes

**Checkpoint**: All configuration prompts and file writes work without Python

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, validation, and documentation updates

- [x] T035 [P] Remove `OPENCLAW_USER_SKILLS`, `OPENCLAW_WORKSPACE_SKILLS` variables if no longer referenced in install.sh
- [x] T036 [P] Update the installer header comment from "Installs MCP server and TRON skills from GitHub" to reflect the new approach in install.sh
- [x] T037 Update final summary section (lines 1030-1081) to reference `npx skills list` for verification instead of directory paths in install.sh
- [x] T038 Run `shellcheck install.sh` and fix any warnings
- [x] T039 Run full end-to-end test: `./install.sh` with all servers and skills selected, verify mcporter.json and config files
- [x] T040 Run pipe-install test: `cat install.sh | bash` to verify `/dev/tty` handling works with npx commands
- [x] T041 Update CLAUDE.md Prerequisites section to remove Python 3 requirement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (MCP) and US2 (Skills) are independent — can run in parallel
  - US3 (Config) depends on US1 and US2 being complete (config functions are called during MCP/skill installation)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1 — MCP)**: Can start after Phase 2 — no dependencies on other stories
- **User Story 2 (P1 — Skills)**: Can start after Phase 2 — no dependencies on other stories
- **User Story 3 (P2 — Config)**: Depends on US1 and US2 (config prompts are triggered during MCP/skill install flows)

### Within Each User Story

- Implementation tasks are sequential (each builds on previous)
- Bash syntax validation is the final task in each phase

### Parallel Opportunities

- Phase 1: T003-T009 can all run in parallel (independent function removals)
- Phase 2: T013-T016 are independent helper functions, but since they all modify install.sh they should be sequential
- Phase 3 and Phase 4 (US1 and US2) can run in parallel if using separate branches
- Phase 6: T035-T036 can run in parallel

---

## Parallel Example: Phase 1 Cleanup

```bash
# These tasks remove independent functions — can run in parallel:
Task T003: "Remove write_server_config() in install.sh"
Task T004: "Remove json_string_or_null() in install.sh"
Task T005: "Remove clear_all_mcp_entries() in install.sh"
Task T006: "Remove clone_skills_repo() in install.sh"
Task T007: "Remove copy_skill() in install.sh"
Task T008: "Remove select_install_target() in install.sh"
Task T009: "Remove pretty_skill_name() in install.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Remove dead Python/git code
2. Complete Phase 2: Add Node.js JSON helpers
3. Complete Phase 3: MCP servers via `npx add-mcp`
4. **STOP and VALIDATE**: Test MCP installation independently
5. Proceed to skills if MCP works

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation ready (Python removed, Node.js helpers in place)
2. Add US1 (MCP) → Test MCP independently → Validate mcporter.json
3. Add US2 (Skills) → Test skills independently → Validate `npx skills list -g`
4. Add US3 (Config) → Test all config prompts → Validate config files
5. Polish → shellcheck, pipe test, CLAUDE.md update

---

## Notes

- All changes are in a single file: `install.sh`
- Since all tasks modify the same file, true parallelism is limited to the branch/worktree level
- Line numbers reference the current install.sh and may shift as earlier tasks modify the file — use function names as anchors
- The `node -e` one-liners must handle the case where config files don't yet exist
- All npx commands need `-y` flag to skip download confirmation in non-interactive pipe mode
