# Changelog

All notable changes to the **OpenClaw Extension** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-03-09

### Added
- **AINFT merchant MCP installer option**: `install.sh` can now register `ainft-merchant` in `~/.mcporter/mcporter.json`
  - Remote endpoint: `https://ainft-agent.bankofai.io/mcp`
- **Current AINFT release notes**: refreshed `RELEASE_NOTE.md` to match the current production setup and installer behavior

### Changed
- **AINFT setup docs aligned to production**:
  - `AINFT_SETUP.md` now documents `https://chat.ainft.com`
  - `setup_ainft.sh` behavior is documented against the current OpenClaw config model
- **AINFT setup model handling clarified**:
  - updates `agents.defaults.model.primary`
  - updates `agents.list.main.model` only when `main` already exists
- **AINFT skill docs simplified**:
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
  - `8004-skill` - On-chain identity, reputation, and validation for AI agents
  - `x402-payment` - Agent payment protocol implementation
  - `x402-payment-demo` - Payment protocol demo

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
