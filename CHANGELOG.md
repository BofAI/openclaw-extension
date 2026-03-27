# Changelog

All notable changes to the **OpenClaw Extension** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.2] - 2026-03-27

### Changed
- **Pinned Skills Release**: The installer now defaults to the `v1.5.2` tag of the [skills repository](https://github.com/BofAI/skills).

## [1.4.0] - 2026-03-21

### Summary
- **Normal install**: keeps existing MCP/skills/config and just walks you through AgentWallet setup first.
- **Clean install**: wipes MCP entries, skills, and local config files, then re-initializes AgentWallet after an explicit confirmation.
- **Wallet handling**: AgentWallet is the unified local signing wallet (no private keys stored in this installer); `bnbchain-mcp` still uses `PRIVATE_KEY`, and sunperp requires `TRON_PRIVATE_KEY`.
- **Defaults pinned**: AgentWallet `2.3.0`, skills `v1.5.0`, `mcp-server-tron@1.1.7`.

## [1.2.14] - 2026-03-15

### Changed
- **Pinned Skills Release**: The installer now defaults to the `v1.4.12` tag of the [skills repository](https://github.com/BofAI/skills).

## [1.2.15] - 2026-03-17

### Changed
- **Pinned Skills Release**: The installer now defaults to the `v1.4.13` tag of the [skills repository](https://github.com/BofAI/skills).

## [1.2.13] - 2026-03-15

### Changed
- **Pinned Skills Release**: The installer now defaults to the `v1.4.11` tag of the [skills repository](https://github.com/BofAI/skills).
- **Aligned Supported Skills**: Removed `x402-payment-demo` from the documented supported skill set to match the current skills release.

## [1.2.12] - 2026-03-15

### Changed
- **Pinned Skills Release**: The installer now defaults to the `v1.4.10` tag of the [skills repository](https://github.com/BofAI/skills) instead of tracking `main`.
- **Installer Skill Set**: Updated installer prompts and documentation to match the current supported skills: `recharge-skill`, `tronscan-skill`, `sunswap`, `x402-payment`, and `x402-payment-demo`.

### Fixed
- **recharge-skill Setup**: Added local `BANKOFAI_API_KEY` configuration guidance for `recharge-skill`.
- **TronScan Skill Setup**: Added `TRONSCAN_API_KEY` setup guidance for `tronscan-skill`.
- **Legacy Cleanup**: Removed outdated `8004-skill` references from installer prompts and docs.

## [1.1.1] - 2026-03-15

### Removed
- **Deprecated x402 demo references**: Removed `x402-payment-demo` references from `README.md` and `install.sh` after the demo skill was deleted from the skills repository.

## [1.1.0] - 2026-03-12

### Added
- **Gasfree API support**: `install.sh` now supports configuring `GASFREE_API_KEY` and `GASFREE_API_SECRET` for the `x402-payment` skill.
- **New Config File**: Added `~/.x402-config.json` to store Gasfree credentials securely.
- **Skills Branch Selection**: The installer now supports a `GITHUB_BRANCH` environment variable for skills installation.

### Changed
- **Default Skills Version**: Updated default skills branch handling for improved compatibility.
- **Enhanced README**: Added dedicated section for Gasfree API credentials and configuration best practices.

### Fixed
- **Recharge Skill Setup**: Resolved several issues in the BANK OF AI recharge skill setup and configuration flow within `install.sh`.

## [1.0.3] - 2026-03-09

### Added
- **BANK OF AI recharge MCP installer option**: `install.sh` can now register `bankofai-recharge` in `~/.mcporter/mcporter.json`
  - Remote endpoint: `https://recharge.bankofai.io/mcp`
- **Documentation refresh**: `RELEASE_NOTE.md` now reflects the current extension scope and installer behavior

### Changed
- **Extension docs simplified**:
  - removed legacy provider setup guidance from extension documentation
  - kept documentation focused on installer-managed MCP servers and skills
- **Recharge skill docs simplified**:
  - production only
  - local balance and order queries only

## [1.0.2] - 2026-02-09

### Added
- **Unified Installer**: Complete rewrite of `install.sh` to handle both MCP server and skills installation
  - Step 1: MCP server configuration with credential storage options
  - Step 2: Skills installation from GitHub with auto-discovery
- **Credential Storage Options**: Users can now choose between two storage methods:
  - Config file storage (convenient, plaintext in `~/.mcporter/mcporter.json`)
  - Environment variables (more secure, recommended)
- **GitHub Skills Integration**: Automatic cloning and installation from [skills](https://github.com/BofAI/skills)
  - Auto-discovery of all available skills
  - Interactive multi-select menu
  - Flexible installation locations (user-level, workspace-level, custom)
- **Available Skills**:
  - `sunswap` - SunSwap DEX trading with multi-version pool routing
  - `tronscan-skill` - TRON blockchain data lookup via the TronScan API
  - `x402-payment` - Agent payment protocol implementation
  - `x402-payment-demo` - Payment protocol demo
  - `recharge-skill` - BANK OF AI balance/order queries and recharge flow

### Changed
- **Removed clawhub dependency**: Skills are now installed directly from GitHub
- **Enhanced security warnings**: Clear explanation of credential storage options
- **Improved installer UX**: Step-by-step process with clear progress indicators
- Uses OpenClaw's official `mcporter` for MCP server configuration

### Security
- Default credential storage method is now environment variables (more secure)
- Added detailed security documentation for both storage methods
- Enhanced warnings about private key handling

## [1.0.1] - 2026-02-06

### 💳 x402-payment Skill (v1.0.1)
- **Rate Limit Protection**: Added support for `TRON_GRID_API_KEY`. The skill now automatically discovers API keys from the environment or configuration files to prevent TronGrid 429 errors.
- **Protocol Update**: Upgraded `@bankofai/x402-tron` to `v0.1.6`.
- **Implementation Fix**: Switched mechanism to `ExactTronClientMechanism` to align with the latest protocol standards.

## [1.0.0] - 2026-02-04

### Initial Release
The first public release of the **OpenClaw Extension**, a comprehensive suite for AI Agents on the TRON network.

### Features

#### 🔗 MCP Server (`mcp-server-tron`)
- **Direct Blockchain Access**: Provides Model Context Protocol (MCP) tools for LLMs to interact directly with TRON.
- **Wallet Management**: Tools to check balances (`get_balance`), validate addresses, and track assets (`get_token_balance`).
- **Transaction Execution**: Support for native TRX transfers and TRC20 token transfers.
- **Smart Contract Interaction**: Generic support for reading (`read_contract`) and writing (`write_contract`) to any smart contract on TRON.
- **Network Intelligence**: Tools to fetch block information, energy prices, and bandwidth costs.

#### 💳 Payment Protocol (`x402-payment`)
- **Autonomous Payments**: A specialized agent skill that implements the **HTTP 402** protocol.
- **Binary Handling**: Automatically streams large binary or image responses to temporary files to optimize LLM context usage.

#### 🛠️ Tooling & Infrastructure
- **Interactive Installer**: A robust `install.sh` script to automate dependency checks, skill selection, and configuration.
- **Security Architecture**:
  - **Secure Storage**: Adopts the `~/.mcporter/mcporter.json` standard for centralized, permissioned credential storage.
  - **Auto-Redaction**: Built-in safety layers to strip private keys from all logs, error stack traces, and outputs.
- **Multi-Network Support**: Full configuration support for **Mainnet**, **Nile** (Testnet), and **Shasta** (Testnet).
