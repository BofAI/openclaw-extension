# Changelog

All notable changes to the **OpenClaw Extension** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-02-06

### 💳 x402-tron-payment Skill (v1.0.1)
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

#### 💳 Payment Protocol (`x402-tron-payment`)
- **Autonomous Payments**: A specialized agent skill that implements the **HTTP 402** protocol.
- **Binary Handling**: Automatically streams large binary or image responses to temporary files to optimize LLM context usage.

#### 🛠️ Tooling & Infrastructure
- **Interactive Installer**: A robust `install.sh` script to automate dependency checks, skill selection, and configuration.
- **Security Architecture**:
  - **Secure Storage**: Adopts the `~/.mcporter/mcporter.json` standard for centralized, permissioned credential storage.
  - **Auto-Redaction**: Built-in safety layers to strip private keys from all logs, error stack traces, and outputs.
- **Multi-Network Support**: Full configuration support for **Mainnet**, **Nile** (Testnet), and **Shasta** (Testnet).
