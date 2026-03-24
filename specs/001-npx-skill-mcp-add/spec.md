# Feature Specification: Use npx skill/mcp add Commands in Installer

**Feature Branch**: `001-npx-skill-mcp-add`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "update install.sh use `npx skill add` to install skills, use `npx mcp add` to install mcp servers(mcporter). and do not forget configurations."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - MCP Server Installation via npx mcp add (Priority: P1)

As a user running the OpenClaw Extension installer, I want MCP servers to be installed using the `npx mcp add` command so that the installation process uses the standard mcporter CLI interface rather than custom Python-based JSON manipulation.

**Why this priority**: MCP server configuration is the core value of the installer. Using the official `npx mcp add` command ensures compatibility with mcporter's expected config format and reduces maintenance burden of custom JSON-writing logic.

**Independent Test**: Run the installer, select one or more MCP servers, and verify that `npx mcp add` is called for each selected server with the correct arguments. Confirm the resulting `mcporter.json` is valid and servers are functional.

**Acceptance Scenarios**:

1. **Given** a user selects mcp-server-tron during installation, **When** the installer proceeds, **Then** `npx mcp add` is invoked with the correct server package name, version, and transport configuration, and the server entry appears in `mcporter.json`.
2. **Given** a user selects bnbchain-mcp and provides a private key, **When** the installer proceeds, **Then** `npx mcp add` is invoked with the correct arguments and the environment variable (PRIVATE_KEY) is passed through to the configuration.
3. **Given** a user selects bankofai-recharge, **When** the installer proceeds, **Then** `npx mcp add` is invoked with the remote MCP URL configuration.
4. **Given** a user is running a clean install, **When** MCP servers are installed, **Then** existing MCP entries are cleared before adding new ones using the standard approach.

---

### User Story 2 - Skills Installation via npx skill add (Priority: P1)

As a user running the installer, I want skills to be installed using the `npx skill add` command so that skills are managed through the standard OpenClaw skill management interface rather than manual git clone and file copy operations.

**Why this priority**: Skills installation is equally critical. Using `npx skill add` ensures skills are registered properly with OpenClaw and eliminates the need for manual git cloning, directory copying, and separate npm install steps.

**Independent Test**: Run the installer, select one or more skills, and verify that `npx skill add` is called for each selected skill. Confirm the skills are properly installed and functional in OpenClaw.

**Acceptance Scenarios**:

1. **Given** a user selects skills (e.g., sunswap, tronscan-skill) during installation, **When** the installer proceeds, **Then** `npx skill add` is invoked for each selected skill with the correct skill identifier.
2. **Given** a skill requires post-install configuration (e.g., recharge-skill needs an API key, tronscan-skill needs TRONSCAN_API_KEY), **When** the skill is installed via `npx skill add`, **Then** the installer still prompts for and configures the required credentials/environment variables.
3. **Given** a user is running a clean install, **When** skills are installed, **Then** existing skills are cleared before adding new ones.

---

### User Story 3 - Configuration Preservation (Priority: P2)

As a user, I want all existing configuration workflows (API keys, environment variables, credential prompts) to be preserved when the installer switches to `npx skill add` and `npx mcp add`, so that I do not lose any setup steps needed for the tools to function.

**Why this priority**: Without proper configuration, installed servers and skills will not work. The configuration prompts are what make the installer valuable beyond manual setup.

**Independent Test**: Run the installer end-to-end, provide configuration values when prompted, and verify all config files (mcporter.json, x402-config.json, bankofai-config.json, environment variables) are correctly written.

**Acceptance Scenarios**:

1. **Given** bnbchain-mcp is selected and the user chooses to save the private key in config, **When** `npx mcp add` is used, **Then** the PRIVATE_KEY environment variable is included in the server configuration.
2. **Given** x402-payment skill is selected, **When** the skill is installed, **Then** the Gasfree API key/secret prompt still runs and `~/.x402-config.json` is created with chmod 600.
3. **Given** recharge-skill is selected, **When** the skill is installed, **Then** the BANK OF AI API key prompt still runs and `~/.mcporter/bankofai-config.json` is updated.
4. **Given** sunperp skill is selected, **When** the skill is installed, **Then** any sunperp-specific configuration prompts are preserved.

---

### Edge Cases

- What happens when `npx mcp add` fails (e.g., network error, invalid package)? The installer should display an error and continue with remaining servers.
- What happens when `npx skill add` fails for a specific skill? The installer should display an error and continue with remaining skills.
- What happens when running in a pipe-install scenario (`curl | bash`)? The `/dev/tty` input handling must still work correctly with the npx commands.
- What happens when the user has no internet connection? The installer should fail gracefully with a clear error message.
- What happens when `npx mcp add` or `npx skill add` commands are not available in the user's npx version? The pre-flight checks should verify availability.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The installer MUST use `npx mcp add` to register each selected MCP server in mcporter configuration, replacing the current Python-based `write_server_config` approach.
- **FR-002**: The installer MUST use `npx skill add` to install each selected skill, replacing the current git-clone-and-copy approach.
- **FR-003**: The installer MUST preserve all existing configuration prompts (API keys, private keys, environment variables) and write configuration files as before.
- **FR-004**: The installer MUST support all currently available MCP servers: mcp-server-tron (v1.1.7), bnbchain-mcp, and bankofai-recharge.
- **FR-005**: The installer MUST support all currently available skills: sunswap, tronscan-skill, x402-payment, recharge-skill, and sunperp.
- **FR-006**: The installer MUST continue to support both normal and clean install modes.
- **FR-007**: The installer MUST remove the Python-based JSON manipulation code that is no longer needed after switching to `npx mcp add`.
- **FR-008**: The installer MUST remove the git clone and manual skill copy logic that is no longer needed after switching to `npx skill add`.
- **FR-009**: The installer MUST continue to work when piped from curl (`curl ... | bash`), maintaining `/dev/tty` input handling.
- **FR-010**: The installer MUST handle failures from `npx mcp add` or `npx skill add` gracefully, displaying errors and continuing with remaining items.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three MCP servers and all five skills install successfully using the new npx-based commands when running the installer end-to-end.
- **SC-002**: The resulting configuration files (mcporter.json, x402-config.json, bankofai-config.json) contain the correct entries and credentials after installation.
- **SC-003**: The installer completes the full installation flow (MCP + skills + configuration) without requiring Python 3 for JSON manipulation.
- **SC-004**: The installer works correctly in both direct execution (`./install.sh`) and pipe execution (`curl ... | bash`) scenarios.

### Assumptions

- The `npx mcp add` command is available through the mcporter package and accepts server configuration (package name, version, transport type, environment variables) as arguments.
- The `npx skill add` command is available through OpenClaw and accepts skill identifiers as arguments.
- Both commands write to the expected configuration locations (`~/.mcporter/mcporter.json` for MCP, `~/.openclaw/skills/` for skills).
- The exact CLI syntax for `npx mcp add` and `npx skill add` will be determined during implementation based on the current versions of mcporter and OpenClaw.
- Python 3 may no longer be a prerequisite if all JSON manipulation is handled by the npx commands.
