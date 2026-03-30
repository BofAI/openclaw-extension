# Implementation Plan: Windows Installer (install.bat)

**Branch**: `002-windows-installer` | **Date**: 2026-03-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-windows-installer/spec.md`

## Summary

Create a Windows-native installer (`install.ps1` + `install.bat` launcher) that mirrors the complete installation flow of `install.sh`. The PowerShell script replicates all four phases — mode selection, AgentWallet setup, MCP server configuration, and skills installation — producing identical configuration files and user experience. A thin `install.bat` wrapper enables frictionless execution without execution policy changes.

## Technical Context

**Language/Version**: PowerShell 5.1+ (ships with Windows 10/11), cmd batch for launcher
**Primary Dependencies**: Node.js v18+ (npx), Git, AgentWallet CLI v2.3.1, add-mcp@1.5.1, skills@1.4.6
**Storage**: JSON config files in `%USERPROFILE%\.mcporter\` and `%USERPROFILE%\`
**Testing**: PowerShell syntax parse check, manual execution test, pipe-install test (`Get-Content install.ps1 -Raw | iex`)
**Target Platform**: Windows 10 (1511+) and Windows 11, cmd.exe and PowerShell
**Project Type**: CLI installer script
**Performance Goals**: N/A — interactive installer, not a performance-critical application
**Constraints**: Must produce byte-identical JSON config content as install.sh; must work in pipe-install mode (`irm URL | iex`)
**Scale/Scope**: Single script (~700 lines PowerShell), single batch launcher (~10 lines)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Single-Script Architecture | VIOLATION — JUSTIFIED | `install.ps1` is the single script for Windows (analogous to `install.sh` for Linux/macOS). `install.bat` is a zero-logic launcher. See Complexity Tracking. |
| II. Pipe-Install Compatibility | PASS | `irm URL \| iex` supported. `Read-Host` naturally reads from console (not stdin), equivalent to `/dev/tty`. |
| III. Ecosystem-Standard Tooling | PASS | Same `npx add-mcp` and `npx skills add` commands — cross-platform Node.js tools. |
| IV. No Python Dependency | PASS | JSON manipulation via `node -e` one-liners, identical approach. |
| V. Pinned Dependencies | PASS | Same pinned versions: add-mcp@1.5.1, skills@1.4.6, agent-wallet@2.3.1, mcp-server-tron@1.1.7. |
| VI. Credential Security | PASS | `icacls` used to restrict config files to owner-only access (Windows equivalent of chmod 600). Secrets passed via environment variables to `node -e`. |

**Post-Phase-1 Re-check**: All items still pass. The data model confirms identical JSON output. The hybrid approach (bat launcher + ps1 logic) is justified and documented.

## Project Structure

### Documentation (this feature)

```text
specs/002-windows-installer/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
install.sh              # Existing Linux/macOS installer (unchanged)
install.bat             # NEW — Thin cmd.exe launcher for install.ps1
install.ps1             # NEW — Windows PowerShell installer (all logic)
```

**Structure Decision**: Flat root — both installer scripts live at the repository root alongside `install.sh`. No subdirectories needed. This matches the existing project structure where `install.sh` is the only application code at the root level.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Second script file (`install.ps1`) | Windows has no bash. PowerShell is the native scripting language. | Embedding all logic in `install.bat` (pure cmd batch) was rejected: batch cannot implement multiselect TUI, has no native ANSI support, and array handling is extremely limited. |
| Third file (`install.bat`) | Users need a frictionless way to run the installer on Windows. `.ps1` files require execution policy bypass. | Shipping only `.ps1` was rejected: double-clicking a `.ps1` opens it in Notepad by default, and users would need `powershell -ep bypass -f install.ps1` which is unfriendly. |

## Key Design Decisions

### 1. Function-by-function port

Each bash function in `install.sh` maps to a PowerShell function in `install.ps1`:

| Bash Function | PowerShell Equivalent |
|---------------|----------------------|
| `check_env()` | `Test-Environment` |
| `node_json_merge()` | `Merge-NodeJson` |
| `node_json_write()` | `Write-NodeJson` |
| `node_json_read()` | `Read-NodeJson` |
| `node_json_reset_mcp()` | `Reset-NodeJsonMcp` |
| `ask_input()` | `Read-UserInput` |
| `run_clean_install()` | `Invoke-CleanInstall` |
| `choose_install_mode()` | `Select-InstallMode` |
| `ensure_agent_wallet_cli()` | `Install-AgentWalletCli` |
| `run_agent_wallet_cli()` | `Invoke-AgentWallet` |
| `setup_agent_wallet()` | `Initialize-AgentWallet` |
| `multiselect()` | `Show-MultiSelect` |
| `configure_*()` | `Set-SkillConfig` (dispatches by skill ID) |

### 2. ANSI color strategy

- Attempt to enable Virtual Terminal Processing via `[Console]::OutputEncoding` and Win32 API.
- If VT processing is unavailable, fall back to `Write-Host -ForegroundColor` with closest 16-color mappings.
- Same color variables as bash (`$BOLD`, `$ACCENT`, `$INFO`, `$SUCCESS`, `$WARN`, `$ERROR`, `$MUTED`, `$NC`).

### 3. Pipe-install I/O

- `Read-Host` always reads from the console in PowerShell, making it naturally pipe-safe.
- For the multiselect function, `[Console]::ReadKey($true)` also reads from the console directly.
- No `/dev/tty` equivalent needed — PowerShell's console I/O is already separated from stdin.

### 4. File permissions

- After writing credential files, run `icacls` to:
  1. Remove inheritance (`/inheritance:r`)
  2. Remove all existing ACEs
  3. Grant current user Read+Write only (`/grant:r "$env:USERNAME:(R,W)"`)

### 5. Constitution amendment required

This feature requires a MINOR constitution amendment (1.0.0 → 1.1.0):
- **Principle I**: Clarify "each supported OS has its own single-script installer"
- **Technology Constraints**: Add "PowerShell 5.1+ on Windows 10+"
- **Quality Gates**: Add Windows equivalents (parse check, PSScriptAnalyzer, direct run, pipe-install test)
