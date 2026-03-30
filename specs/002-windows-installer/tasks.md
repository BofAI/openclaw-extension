# Tasks: Windows Installer (install.bat)

**Input**: Design documents from `/specs/002-windows-installer/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Not explicitly requested in the feature specification. Tests are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flat root**: `install.bat` and `install.ps1` at repository root alongside existing `install.sh`
- All logic resides in `install.ps1`; `install.bat` is a thin launcher

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the two new files and establish the PowerShell script scaffold

- [x] T001 Create thin cmd.exe launcher in `install.bat` that invokes `install.ps1` with `-NoProfile -ExecutionPolicy Bypass` flags, supports being run from any directory (use `%~dp0` for script-relative path), and exits with the PowerShell exit code
- [x] T002 Create `install.ps1` scaffold with `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`, global try/finally block for cleanup (restore `[Console]::CursorVisible`), and empty function stubs for all functions listed in plan.md function mapping table

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utility functions that ALL user stories depend on — these must be complete before any installer phase can work

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Implement ANSI color initialization in `install.ps1`: define `$BOLD`, `$ACCENT`, `$ACCENT_DIM`, `$INFO`, `$SUCCESS`, `$WARN`, `$ERROR_COLOR`, `$MUTED`, `$NC` variables using `` `e `` escape sequences matching the exact RGB values in `install.sh`; add `Enable-VirtualTerminal` function that calls `SetConsoleMode` via P/Invoke to enable `ENABLE_VIRTUAL_TERMINAL_PROCESSING` on stdout handle; detect if VT is available and fall back to empty strings if not
- [x] T004 [P] Implement `Merge-NodeJson` function in `install.ps1` — port of `node_json_merge()` from `install.sh`: accepts `$ServerId`, `$EnvJson`, `$ConfigFile` parameters; calls `node -e` with env vars `MCP_FILE`, `SERVER_ID`, `ENV_JSON` using the identical JavaScript one-liner from install.sh lines 98-118
- [x] T005 [P] Implement `Write-NodeJson` function in `install.ps1` — port of `node_json_write()` from `install.sh`: accepts `$FilePath`, `$JsonContent` parameters; calls `node -e` with env vars `FILE_PATH`, `JSON_CONTENT` using the identical JavaScript one-liner from install.sh lines 121-133
- [x] T006 [P] Implement `Read-NodeJson` function in `install.ps1` — port of `node_json_read()` from `install.sh`: accepts `$FilePath`, `$Key` parameters; calls `node -e` with env vars `FILE_PATH`, `JSON_KEY` using the identical JavaScript one-liner from install.sh lines 136-151; returns the captured stdout string
- [x] T007 [P] Implement `Reset-NodeJsonMcp` function in `install.ps1` — port of `node_json_reset_mcp()` from `install.sh`: accepts `$ConfigFile` parameter; calls `node -e` with env var `MCP_FILE` using the identical JavaScript one-liner from install.sh lines 154-167
- [x] T008 [P] Implement `Read-UserInput` function in `install.ps1` — port of `ask_input()` from `install.sh`: accepts `$Prompt`, `$VarName` (returns value instead), `$IsSecret` (bool), `$Description` (optional) parameters; uses `Read-Host` (with `-AsSecureString` for secrets, then convert back to plain text) to read from console; displays prompt with same formatting as bash version
- [x] T009 [P] Implement `Set-FileOwnerOnly` helper function in `install.ps1`: accepts `$FilePath` parameter; uses `icacls` to remove inheritance (`/inheritance:r`), remove all existing ACEs, and grant only `$env:USERNAME` read+write access (`/grant:r "$env:USERNAME:(R,W)"`); pipe output to `Out-Null`; this is the Windows equivalent of `chmod 600`
- [x] T010 Implement `Show-MultiSelect` function in `install.ps1` — port of `multiselect()` from `install.sh` (lines 332-478): accepts `$Prompt` (string) and `$Options` (string array, supporting `||` separator for name/description); uses `[Console]::CursorVisible = $false`, `[Console]::ReadKey($true)` for arrow key navigation (UpArrow/DownArrow), Space to toggle, Enter to confirm; renders checkbox UI with ANSI colors matching bash version; wraps description lines to terminal width; returns array of selected indices; restores cursor visibility in finally block

**Checkpoint**: All utility functions ready — user story implementation can now begin

---

## Phase 3: User Story 1 - Windows User Runs Installer (Priority: P1) MVP

**Goal**: End-to-end installer runs on Windows, displaying branded banner, checking prerequisites, and orchestrating all phases

**Independent Test**: Run `install.bat` on Windows with all prerequisites installed; installer starts, shows banner, and proceeds through all phases

### Implementation for User Story 1

- [x] T011 [P] [US1] Implement taglines array and `Get-Tagline` function in `install.ps1`: define `$TAGLINES` array with the same 8 tagline strings from `install.sh` lines 42-51; implement random selection using `Get-Random`
- [x] T012 [P] [US1] Implement `Test-Environment` function in `install.ps1` — port of `check_env()` from `install.sh` (lines 63-89): check `node` is in PATH and version is v18+ (parse `node --version`); check `npx` is in PATH; check `git` is in PATH; check `$env:USERPROFILE\.openclaw` directory exists; display same colored error/warning messages; prompt to continue if OpenClaw not found using `Read-Host`; exit on missing hard prerequisites
- [x] T013 [US1] Implement main script body in `install.ps1` — port of the main logic from `install.sh` (lines 632-858): display branded banner with lobster emoji and tagline; call `Test-Environment`; create config directory (`$env:USERPROFILE\.mcporter`); call `Select-InstallMode` (Phase 4); call `Initialize-AgentWallet` (Phase 4); run MCP server configuration step (Phase 5); run skills installation step (Phase 6); display final summary with same formatting as bash version (installed MCP servers, installed skills, next steps with per-skill test suggestions, repository links); wrap everything in the global try/finally cleanup block

**Checkpoint**: At this point, the installer runs end-to-end on Windows (empty stubs for phases filled in subsequent stories)

---

## Phase 4: User Story 2 - Installation Mode & AgentWallet (Priority: P1)

**Goal**: Mode selection (Normal/Clean) and AgentWallet setup work identically to bash version

**Independent Test**: Run installer, select Clean mode, verify confirmation prompts match bash behavior and correct files are deleted; run again in Normal mode, verify config preserved

### Implementation for User Story 2

- [x] T014 [P] [US2] Implement `Select-InstallMode` function in `install.ps1` — port of `choose_install_mode()` from `install.sh` (lines 236-252): display "Installation Mode" header; show options 1) Normal [Recommended] and 2) Clean; read choice via `Read-Host`; default to 1; set `$script:CleanInstall = $true` and call `Invoke-CleanInstall` if option 2 selected
- [x] T015 [P] [US2] Implement `Invoke-CleanInstall` function in `install.ps1` — port of `run_clean_install()` from `install.sh` (lines 195-234): display same warning banner with exclamation marks; list same files that will be deleted (using `$env:USERPROFILE` paths); prompt y/N confirmation via `Read-Host`; prompt to type "CLEAN" for second confirmation; on confirm: call `Reset-NodeJsonMcp`, run `npx -y skills remove -a openclaw --all -y -g`, run `npx -y skills remove -a openclaw --all -y`, delete `$env:USERPROFILE\.x402-config.json` and `$env:USERPROFILE\.mcporter\bankofai-config.json` using `Remove-Item -ErrorAction SilentlyContinue`
- [x] T016 [US2] Implement `Install-AgentWalletCli` function in `install.ps1` — port of `ensure_agent_wallet_cli()` from `install.sh` (lines 254-286): check if `@bankofai/agent-wallet` is globally installed at correct version via `npm list -g --depth=0`; parse version from output; install/update via `npm install -g "@bankofai/agent-wallet@$AgentWalletVersion"` if needed; verify post-install version matches
- [x] T017 [US2] Implement `Invoke-AgentWallet` and `Initialize-AgentWallet` functions in `install.ps1` — port of `run_agent_wallet_cli()` and `setup_agent_wallet()` from `install.sh` (lines 288-329): `Invoke-AgentWallet` calls `agent-wallet` with forwarded arguments; `Initialize-AgentWallet` calls `Install-AgentWalletCli`, then runs `agent-wallet start --save-runtime-secrets` (or with `--override` and preceded by `agent-wallet reset` in clean mode); display same step header, status messages, and error handling

**Checkpoint**: Mode selection and AgentWallet setup work independently on Windows

---

## Phase 5: User Story 3 - MCP Server Configuration (Priority: P1)

**Goal**: Interactive multiselect for MCP servers, credential collection, and JSON config writing produce identical results to bash version

**Independent Test**: Run installer through MCP step, select servers, provide credentials; verify `mcporter.json` content matches what `install.sh` would produce

### Implementation for User Story 3

- [x] T018 [US3] Implement MCP server configuration block in `install.ps1` main body — port of Step 1 from `install.sh` (lines 648-749): define `$ServerOptions` array with same 3 options (mcp-server-tron, bnbchain-mcp, bankofai-recharge) using `||` separator for descriptions; define `$ServerIds` array; call `Show-MultiSelect` to get selected indices; iterate selected servers with a switch block dispatching to per-server configuration logic
- [x] T019 [P] [US3] Implement mcp-server-tron configuration in `install.ps1` within the MCP switch block: display same info text; call `Read-UserInput` for TRONGRID_API_KEY (secret); run `npx -y add-mcp -a mcporter -n mcp-server-tron -g -y "@bankofai/mcp-server-tron@1.1.7"`; if API key provided, build env JSON via `node -e` with `TRON_KEY` env var and call `Merge-NodeJson`
- [x] T020 [P] [US3] Implement bnbchain-mcp configuration in `install.ps1` within the MCP switch block: display same AgentWallet incompatibility warning and plaintext storage warning; call `Read-UserInput` for PRIVATE_KEY (secret) and LOG_LEVEL; run `npx -y add-mcp -a mcporter -n bnbchain-mcp -g -y "@bnb-chain/mcp@latest"`; add "0x" prefix to key if not present (matching `install.sh` line 718-722); build env JSON via `node -e` and call `Merge-NodeJson`
- [x] T021 [P] [US3] Implement bankofai-recharge configuration in `install.ps1` within the MCP switch block: run `npx -y add-mcp -a mcporter -n bankofai-recharge -g -t http -y "https://recharge.bankofai.io/mcp"`
- [x] T022 [US3] Implement post-MCP file permission restriction in `install.ps1`: after all MCP servers are configured, call `Set-FileOwnerOnly` on `$McpConfigFile` (equivalent to `chmod 600 "$MCP_CONFIG_FILE"` at install.sh line 748)

**Checkpoint**: MCP server configuration produces identical `mcporter.json` to bash version

---

## Phase 6: User Story 4 - Skills Installation (Priority: P1)

**Goal**: Skills scope selection, interactive installation via npx, and post-install configuration produce identical results to bash version

**Independent Test**: Run installer through skills step, select scope and skills; verify skills installed at correct scope and config files created with correct content

### Implementation for User Story 4

- [x] T023 [US4] Implement skills scope selection in `install.ps1` main body — port of Step 2 scope choice from `install.sh` (lines 751-776): display "Skills Installation" header; show options 1) User-level (global) [Recommended] and 2) Workspace-level; read choice via `Read-Host`; set `$SkillsGlobalFlag` to `-g` or empty string accordingly
- [x] T024 [US4] Implement skills installation and diff detection in `install.ps1` — port of `install.sh` lines 778-805: snapshot installed skills before via `npx -y skills@1.4.6 list $SkillsGlobalFlag -a openclaw --json`; run `npx -y skills@1.4.6 add "$SkillsRepo" -a openclaw $SkillsGlobalFlag` interactively; snapshot after; diff before/after using `node -e` with same JavaScript logic from install.sh lines 789-793 to find newly installed skill names; store in `$InstalledSkills` array
- [x] T025 [P] [US4] Implement `Set-SkillConfig` function in `install.ps1` — port of `configure_skill()` and all `configure_*` sub-functions from `install.sh` (lines 608-628): dispatch by skill ID; for "sunperp": display TRON_PRIVATE_KEY dependency warning; for "x402-payment": call `Set-X402GasfreeConfig`; for "recharge-skill": call `Set-BankOfAiApiKeyConfig`; for "tronscan-skill": call `Set-TronscanApiKeyConfig`
- [x] T026 [P] [US4] Implement `Set-BankOfAiApiKeyConfig` function in `install.ps1` — port of `configure_bankofai_api_key()` from `install.sh` (lines 482-529): check if `$env:USERPROFILE\.mcporter\bankofai-config.json` exists with valid `api_key`; prompt to reconfigure if exists; read BANKOFAI_API_KEY via `Read-Host -AsSecureString`; build JSON via `node -e` with `BANKOFAI_API_KEY` env var; call `Write-NodeJson`; call `Set-FileOwnerOnly` on the config file
- [x] T027 [P] [US4] Implement `Set-TronscanApiKeyConfig` function in `install.ps1` — port of `configure_tronscan_api_key()` from `install.sh` (lines 531-547): check if `$env:TRONSCAN_API_KEY` is set; if yes, show success message; if no, display instructions to add `$env:TRONSCAN_API_KEY` to PowerShell profile (`$PROFILE`) and provide the tronscan.org key URL
- [x] T028 [P] [US4] Implement `Set-X402GasfreeConfig` function in `install.ps1` — port of `configure_x402_gasfree()` from `install.sh` (lines 549-606): check if `$env:USERPROFILE\.x402-config.json` exists with valid `gasfree_api_key` and `gasfree_api_secret`; prompt to reconfigure if exists; read both credentials via `Read-Host` (secret for API secret); build JSON via `node -e`; call `Write-NodeJson`; call `Set-FileOwnerOnly` on the config file
- [x] T029 [US4] Implement post-install skill configuration loop and final summary in `install.ps1` — port of install.sh lines 795-858: iterate `$InstalledSkills` and call `Set-SkillConfig` for each; display final summary banner matching bash version: show MCP config file path, list installed skills with bullets, show "next steps" with per-skill test suggestions (same suggestion strings), show repository URLs

**Checkpoint**: Full installer flow complete — all 4 phases functional on Windows

---

## Phase 7: User Story 5 - Cross-OS Parity & Documentation (Priority: P2)

**Goal**: Ensure verifiable parity between `install.sh` and `install.ps1`, update project documentation and constitution

**Independent Test**: Run both installers with identical inputs on their respective platforms; compare resulting config files for identical JSON content

### Implementation for User Story 5

- [x] T030 [P] [US5] Update constitution in `.specify/memory/constitution.md`: bump version to 1.1.0; amend Principle I to clarify "each supported OS has its own single-script installer (`install.sh` for Linux/macOS, `install.ps1` for Windows)"; add "PowerShell 5.1+ on Windows 10+" to Technology Constraints; add Windows quality gates (PowerShell parse check, PSScriptAnalyzer, direct run test, pipe-install test via `Get-Content install.ps1 -Raw | iex`)
- [x] T031 [P] [US5] Update `CLAUDE.md`: add `install.ps1` and `install.bat` to Architecture section; add Windows development commands (syntax check, run, pipe-install test); update Pinned Versions table if needed; add note about install.bat being a thin launcher
- [x] T032 [P] [US5] Update `README.md`: add Windows installation instructions (both `install.bat` and `irm | iex` one-liner); note Windows 10+ requirement; add Windows-specific prerequisites (PowerShell 5.1+)

**Checkpoint**: Documentation reflects dual-OS installer support

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge case handling, robustness, and final validation

- [x] T033 [P] Ensure all file paths in `install.ps1` are properly quoted to handle spaces in `$env:USERPROFILE` (e.g., `C:\Users\John Doe`)
- [x] T034 [P] Add graceful error handling for `npx` network failures in `install.ps1`: wrap each `npx` call in try/catch; display same error messages as bash version (e.g., "Failed to add mcp-server-tron via npx add-mcp"); use `continue` to skip to next server/skill on failure
- [x] T035 [P] Verify `install.bat` works when invoked from both cmd.exe and PowerShell (test `%~dp0` path resolution in both shells)
- [x] T036 Perform line-by-line parity review of `install.ps1` against `install.sh`: verify every user-facing string (prompts, errors, success messages, banner text) matches; verify every `npx` command uses identical arguments and version pins; verify JSON output from `node -e` calls is identical

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T002 (scaffold) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion (needs all helper functions)
- **US2 (Phase 4)**: Depends on Phase 2 completion; can run in parallel with US1
- **US3 (Phase 5)**: Depends on Phase 2 completion and T010 (multiselect); can run in parallel with US1/US2
- **US4 (Phase 6)**: Depends on Phase 2 completion; can run in parallel with US1/US2/US3
- **US5 (Phase 7)**: Depends on US1-US4 completion (needs final install.ps1 to document)
- **Polish (Phase 8)**: Depends on US1-US4 completion

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 — provides the end-to-end skeleton
- **User Story 2 (P1)**: Depends on Phase 2 — independent of US1 (fills in mode selection stubs)
- **User Story 3 (P1)**: Depends on Phase 2 + T010 (multiselect) — independent of US1/US2
- **User Story 4 (P1)**: Depends on Phase 2 — independent of US1/US2/US3
- **User Story 5 (P2)**: Depends on US1-US4 — documentation/constitution updates

### Within Each User Story

- Functions can be implemented in any order within a story (all target the same file)
- Main body orchestration (T013) should be done after individual functions are ready
- Post-configuration tasks depend on their prerequisite functions

### Parallel Opportunities

- T003-T010 (all foundational functions) can run in parallel — they are independent functions
- T011-T012 (US1 functions) can run in parallel
- T014-T015 (US2 mode functions) can run in parallel with T016-T017 (US2 wallet functions)
- T019-T021 (US3 per-server configs) can run in parallel
- T025-T028 (US4 per-skill configs) can run in parallel
- T030-T032 (US5 documentation) can run in parallel
- T033-T035 (Polish edge cases) can run in parallel
- **Note**: Since all implementation targets a single file (`install.ps1`), true parallelism requires merge coordination. Sequential execution within the file is recommended for a single developer.

---

## Parallel Example: Phase 2 (Foundational)

```
# All foundational functions target different sections of install.ps1:
Task T003: "ANSI color initialization" (top of file, constants section)
Task T004: "Merge-NodeJson function" (JSON helpers section)
Task T005: "Write-NodeJson function" (JSON helpers section)
Task T006: "Read-NodeJson function" (JSON helpers section)
Task T007: "Reset-NodeJsonMcp function" (JSON helpers section)
Task T008: "Read-UserInput function" (input helpers section)
Task T009: "Set-FileOwnerOnly function" (file helpers section)
Task T010: "Show-MultiSelect function" (UI section)
```

---

## Implementation Strategy

### MVP First (User Stories 1-4)

1. Complete Phase 1: Setup — create `install.bat` and `install.ps1` scaffold
2. Complete Phase 2: Foundational — all utility functions
3. Complete Phase 3: US1 — end-to-end skeleton with banner and pre-flight checks
4. Complete Phase 4: US2 — mode selection and AgentWallet
5. Complete Phase 5: US3 — MCP server configuration
6. Complete Phase 6: US4 — skills installation and summary
7. **STOP and VALIDATE**: Run full installer on Windows, compare output with bash version
8. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Scaffold ready
2. Add US1 → Installer starts and shows banner (skeleton MVP)
3. Add US2 → Mode selection and AgentWallet work
4. Add US3 → MCP server configuration works
5. Add US4 → Full installer flow complete
6. Add US5 → Documentation updated
7. Polish → Edge cases handled

---

## Notes

- All user stories target the same two files (`install.ps1` and `install.bat`), so parallelism is limited to non-overlapping sections
- The `node -e` JavaScript one-liners MUST be copied verbatim from `install.sh` — they are cross-platform
- Every `Read-Host` call is naturally pipe-safe in PowerShell (reads from console, not stdin)
- Use `$env:USERPROFILE` everywhere bash uses `$HOME` or `~`
- PowerShell uses `$null` where bash uses `2>/dev/null` (redirect stderr: `2>$null`)
- PowerShell uses `-ErrorAction SilentlyContinue` where bash uses `|| true`
