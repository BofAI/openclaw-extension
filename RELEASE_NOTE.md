# Release Notes: OpenClaw Extension v1.0.0

**Date**: February 4, 2026  
**Version**: 1.0.0

## 🚀 Overview
We are excited to announce the launch of **OpenClaw Extension v1.0.0**, the definitive toolkit for AI Agents on the TRON network. 

This release introduces two powerful pillars that transform how agents interact with the blockchain economy: **Direct Blockchain Access** (via MCP) and **Autonomous Payments** (via x402).

## ✨ Major Features

### 1. 🔗 mcp-server-tron
The bridge between your LLM and the TRON blockchain.
- **What it is**: An [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes TRON blockchain capabilities as tool-use functions for AI.
- **Capabilities**:
  - **Wallet**: Check balances (`get_balance`), track assets (`get_token_balance`).
  - **DeFi**: Execute token transfers (`transfer_trc20`), interact with any smart contract (`read_contract`, `write_contract`).
  - **Network**: Monitor chain state, block height, and energy costs.
- **Integration**: Works out-of-the-box with any MCP-compliant client (Claude Desktop, Cursor, etc.).

### 2. 💳 x402-payment
The financial layer for the agent economy.
- **What it is**: A specialized agent skill implementing the **HTTP 402** protocol.
- **Use Case**: Enables agents to consume paid APIs seamlessly. When an agent hits a paywall (402 status), this skill intercepts the request, negotiates the price, pays in USDT, and retries the request—all autonomously.
- **Features**:
  - **Smart Approvals**: Optimizes gas usage with intelligent token approval strategies.
  - **Settlement**: verifiable on-chain settlement for every API call.

## 🛠 Installation & Setup

We've introduced a new interactive installer to get you started in seconds.

```bash
# Install / Update to v1.0.0
curl -fsSL https://raw.githubusercontent.com/bankofai/openclaw-extension/refs/heads/main/install.sh | bash
```

The installer will:
1.  Set up the `mcp-server-tron` in your `mcporter` configuration.
2.  Install the `x402-payment` skill and other selected skills.
3.  Securely configure your TRON credentials locally.

## 🔗 Links
- **MCP Server Source**: [bankofai/mcp-server-tron](https://github.com/bankofai/mcp-server-tron)
- **Extension Repo**: [bankofai/openclaw-extension](https://github.com/bankofai/openclaw-extension)
