# Feature Specification: Windows Installer (install.bat)

**Feature Branch**: `002-windows-installer`
**Created**: 2026-03-25
**Status**: Draft
**Input**: User description: "implement 'install.bat' for windows os corresponding to install.sh (make sure logic align between different os)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Windows User Runs Installer (Priority: P1)

A Windows user wants to set up the OpenClaw Extension on their Windows machine. They download or run `install.bat` and are guided through the same installation flow as Linux/macOS users running `install.sh` — mode selection, AgentWallet setup, MCP server configuration, and skills installation.

**Why this priority**: This is the core purpose of the feature. Without a working end-to-end installer on Windows, no other functionality matters.

**Independent Test**: Can be fully tested by running `install.bat` on a Windows machine with Node.js, Git, and OpenClaw pre-installed. The installer completes all phases and produces the same configuration files as `install.sh` would on Linux/macOS.

**Acceptance Scenarios**:

1. **Given** a Windows machine with Node.js v18+, Git, and OpenClaw installed, **When** the user runs `install.bat`, **Then** the installer displays the same branded banner and proceeds through all installation phases (mode selection, AgentWallet, MCP servers, skills).
2. **Given** a Windows machine missing Node.js, **When** the user runs `install.bat`, **Then** the installer displays an error message and exits gracefully.
3. **Given** a Windows machine with all prerequisites, **When** the user completes the installer, **Then** the same configuration files are written to the same relative user paths (`%USERPROFILE%\.mcporter\mcporter.json`, `%USERPROFILE%\.x402-config.json`, etc.) with equivalent content to what `install.sh` produces.

---

### User Story 2 - Windows User Selects Installation Mode (Priority: P1)

A Windows user is presented with the same Normal vs. Clean installation mode choice. Clean mode performs the same destructive cleanup (MCP reset, skills removal, config deletion) with the same two-step confirmation (y/N + type "CLEAN").

**Why this priority**: Mode selection is fundamental to the installer flow and must behave identically to the bash version to ensure cross-OS consistency.

**Independent Test**: Can be tested by running `install.bat` and choosing Clean mode, verifying the confirmation prompts match the bash installer's behavior and that the correct files are removed.

**Acceptance Scenarios**:

1. **Given** the installer is running, **When** the user selects Normal mode (option 1), **Then** existing configuration is preserved and the installer proceeds.
2. **Given** the installer is running, **When** the user selects Clean mode (option 2) and confirms with "y" and "CLEAN", **Then** MCP entries are reset, skills are removed, x402 config and bankofai config are deleted.
3. **Given** the installer is running in Clean mode, **When** the user types anything other than "CLEAN" at the second confirmation, **Then** the clean install is cancelled and the installer falls back to normal mode.

---

### User Story 3 - Windows User Configures MCP Servers (Priority: P1)

A Windows user is presented with an interactive multi-select menu to choose which MCP servers to install. The same three servers are available: mcp-server-tron, bnbchain-mcp, and bankofai-recharge. Server registration uses the same `npx add-mcp` commands. Environment variables and JSON configuration are written identically.

**Why this priority**: MCP server configuration is a core installation phase that must produce identical results across operating systems.

**Independent Test**: Can be tested by running the installer, selecting MCP servers, and verifying that `mcporter.json` contains the same structure and values as when installed via `install.sh`.

**Acceptance Scenarios**:

1. **Given** the MCP configuration step, **When** the user selects mcp-server-tron and provides a TRONGRID_API_KEY, **Then** `npx add-mcp` is called with the same arguments and the API key is merged into `mcporter.json`.
2. **Given** the MCP configuration step, **When** the user selects bnbchain-mcp and provides a PRIVATE_KEY without "0x" prefix, **Then** the "0x" prefix is automatically added and the key is stored in `mcporter.json`.
3. **Given** the MCP configuration step, **When** the user selects bankofai-recharge, **Then** the remote HTTP MCP endpoint is registered via `npx add-mcp`.
4. **Given** MCP configuration is complete, **When** `mcporter.json` is written, **Then** its file permissions are set to owner-only read/write.

---

### User Story 4 - Windows User Installs Skills (Priority: P1)

A Windows user selects the skills installation scope (global vs. workspace) and is guided through the interactive `npx skills add` flow. Post-installation configuration prompts for specific skills (x402-payment, recharge-skill, tronscan-skill, sunperp) behave identically to the bash version.

**Why this priority**: Skills installation is the final core phase. Newly installed skills must receive the same post-install configuration prompts (API keys, credential files).

**Independent Test**: Can be tested by running the installer through the skills phase, verifying skills are installed at the correct scope, and that configuration files (`.x402-config.json`, `bankofai-config.json`) are created with correct content.

**Acceptance Scenarios**:

1. **Given** the skills installation step, **When** the user selects global scope, **Then** skills are installed with the `-g` flag via `npx skills add`.
2. **Given** x402-payment skill was just installed, **When** the user provides Gasfree API credentials, **Then** `~/.x402-config.json` is created with the credentials and restricted file permissions.
3. **Given** the installer completes, **When** skills were installed, **Then** a summary lists all installed skills and provides the same "next steps" guidance as the bash installer.

---

### User Story 5 - Cross-OS Parity Verification (Priority: P2)

A developer or QA engineer wants to verify that `install.bat` and `install.sh` produce functionally identical outcomes — same configuration files, same prompts, same installation flow, same error messages — so that documentation and support materials apply uniformly to both platforms.

**Why this priority**: The explicit requirement is logic alignment between operating systems. This story ensures that parity is verifiable, not just assumed.

**Independent Test**: Can be tested by running both installers with the same inputs on their respective platforms and comparing the resulting configuration files and terminal output step-by-step.

**Acceptance Scenarios**:

1. **Given** identical user inputs on Windows and Linux/macOS, **When** both installers complete, **Then** the resulting `mcporter.json` files contain identical MCP server entries.
2. **Given** identical user inputs on Windows and Linux/macOS, **When** both installers complete, **Then** the resulting skills installations are identical (same skills, same scope).
3. **Given** identical user inputs on Windows and Linux/macOS, **When** both installers complete, **Then** the resulting credential/config files (`.x402-config.json`, `bankofai-config.json`) contain identical content.

---

### Edge Cases

- What happens when the user runs `install.bat` from PowerShell instead of cmd.exe?
- What happens when `%USERPROFILE%` contains spaces (e.g., `C:\Users\John Doe`)?
- What happens when Node.js is installed but not in the system PATH?
- What happens when the user lacks write permissions to `%USERPROFILE%\.mcporter\`?
- What happens when `npx` fails due to network issues mid-installation?
- What happens when the multiselect UI encounters a terminal that doesn't support ANSI escape codes (e.g., legacy cmd.exe)?
- How does the installer handle Ctrl+C interruption on Windows?
- What happens when a previous partial installation left orphaned config files?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The installer MUST provide a `install.bat` file that runs on Windows (cmd.exe and PowerShell) and executes the same installation flow as `install.sh`
- **FR-002**: The installer MUST check for the same prerequisites: Node.js v18+, Git, npx, and OpenClaw (`%USERPROFILE%\.openclaw` directory)
- **FR-003**: The installer MUST offer the same two installation modes: Normal (preserve existing config) and Clean (wipe with two-step confirmation)
- **FR-004**: The installer MUST run AgentWallet setup using the same CLI commands and version (v2.3.0) with the same flags (`--save-runtime-secrets`, `--override` for clean mode)
- **FR-005**: The installer MUST present the same three MCP servers for selection (mcp-server-tron, bnbchain-mcp, bankofai-recharge) and use `npx add-mcp@1.5.1` for registration
- **FR-006**: The installer MUST collect the same optional credentials (TRONGRID_API_KEY, BNB PRIVATE_KEY, LOG_LEVEL) and write them to `mcporter.json` using the same JSON structure
- **FR-007**: The installer MUST add "0x" prefix to BNB PRIVATE_KEY if not present, matching the bash behavior
- **FR-008**: The installer MUST delegate skills selection to `npx skills@1.4.6 add` in interactive mode, same as `install.sh`
- **FR-009**: The installer MUST offer the same skills scope selection (global vs. workspace) and pass the `-g` flag accordingly
- **FR-010**: The installer MUST run post-install configuration for newly installed skills (x402-payment, recharge-skill, tronscan-skill, sunperp) with the same prompts and file outputs
- **FR-011**: The installer MUST write credential files (`.x402-config.json`, `bankofai-config.json`) with restricted permissions (Windows ACL equivalent of chmod 600)
- **FR-012**: The installer MUST display the same branded banner, taglines, color-coded output, and final summary as `install.sh`
- **FR-013**: The installer MUST handle user interruption (Ctrl+C) gracefully with appropriate cleanup
- **FR-014**: The installer MUST support file paths containing spaces in the user profile directory
- **FR-015**: The installer MUST use `node -e` one-liners for JSON manipulation, consistent with the bash installer's approach (no Python dependency)

### Key Entities

- **Installer Script (`install.bat`)**: The Windows batch/script counterpart to `install.sh`, containing all installation logic
- **Configuration Files**: Same set of JSON configuration files written to the user's home directory (`%USERPROFILE%` on Windows, `$HOME` on Linux/macOS)
- **MCP Servers**: The three registrable MCP servers with their specific `npx add-mcp` commands and environment variables
- **Skills**: The set of installable skills from the BofAI/skills repository with their post-install configuration requirements

## Assumptions

- Windows users have cmd.exe or PowerShell available (standard on all supported Windows versions)
- Node.js, Git, and npm/npx are installed and available in the system PATH on Windows
- The `npx add-mcp` and `npx skills add` commands work identically on Windows as on Linux/macOS (they are Node.js-based cross-platform tools)
- Windows ANSI escape code support is available (Windows 10 1511+ cmd.exe and PowerShell support ANSI colors)
- The `agent-wallet` CLI works on Windows (it is a Node.js global package)
- The interactive multiselect UI from `install.sh` may need to be adapted for Windows terminal input handling, but the selection behavior and defaults remain the same
- File permission restrictions on Windows will use Windows ACL mechanisms (e.g., `icacls`) rather than Unix `chmod`, but the intent (owner-only access) is the same

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Windows user can complete the full installation flow (all 4 phases) in a single `install.bat` run without manual workarounds
- **SC-002**: Configuration files produced by `install.bat` on Windows are byte-for-byte identical in content (JSON structure and values) to those produced by `install.sh` on Linux/macOS given the same user inputs
- **SC-003**: All user-facing prompts, messages, and error text in `install.bat` match those in `install.sh` (accounting only for OS-specific path formatting differences)
- **SC-004**: The installer handles all edge cases (spaces in paths, missing prerequisites, user cancellation) without crashing or producing corrupted configuration
- **SC-005**: 100% of the installation phases present in `install.sh` are represented in `install.bat` with equivalent functionality
