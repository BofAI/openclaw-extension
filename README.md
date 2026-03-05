# OpenClaw Extension

OpenClaw Extension is a suite of tools developed by **BankofAI** to empower AI Agents with financial sovereignty. It enables agents to hold wallets, execute transactions, and monetize services using the **x402 Protocol** (HTTP 402 Payment Required).

## 🚀 Mission

To build the "Central Bank" for the agent economy, ensuring every AI agent can:
- **Earn**: Accept payments for tasks and services via standard protocols.
- **Spend**: Pay for resources (computation, data, storage) autonomously.
- **Connect**: Facilitate direct Agent-to-Agent (A2A) financial activities and settlements.
- **Transact**: Interact with DeFi and smart contracts seamlessly.

## 📦 Core Components

This extension provides two main components:

### 1. MCP Servers

Multi-chain blockchain access for AI agents via Model Context Protocol (MCP):

- **[mcp-server-tron](https://github.com/bankofai/mcp-server-tron)** - TRON blockchain interaction
  - Balance checks, transfers, smart contract calls
  - Resource estimation (Energy/Bandwidth)
  - Multi-network support (Mainnet, Nile, Shasta)

- **[bnbchain-mcp](https://github.com/bnb-chain/bnbchain-mcp)** - BNB Chain official MCP server
  - Multi-chain support: BSC, opBNB, Ethereum, Greenfield
  - Wallet operations, smart contracts, token transfers
  - Cross-chain capabilities

### 2. Skills

Pre-built workflows and tools from the **[skills repository](https://github.com/BofAI/skills)**:

**Available Skills:**
- **sunswap** - SunSwap DEX trading skill for TRON token swaps
- **8004-skill** - 8004 Trustless Agents (on-chain identity, reputation, and validation for AI agents on TRON & BSC)
- **x402-payment** - Enables agent payments on TRON network (x402 protocol)
- **x402-payment-demo** - Demo of x402 payment protocol

For complete documentation and usage instructions, see the [skills repository](https://github.com/BofAI/skills).

The installer will let you select which skills to install during setup.

## 🛠 Installation

### Prerequisites
- **OpenClaw** (Your personal, open-source AI assistant) - [Install from here](https://github.com/openclaw)
- **Node.js** (v18+)
- **Python 3** (for configuration helpers)
- **Git** (for cloning skills repository)
- **TRON Wallet** (via agent-wallet encrypted keystore, or TronGrid API Key for read-only)

**Note**: This installer uses OpenClaw's configuration system. Make sure OpenClaw is installed before running this installer.

### Quick Start

**One-command installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

Or from source:

```bash
git clone https://github.com/BofAI/openclaw-extension.git
cd openclaw-extension
./install.sh
```

### What Gets Installed

- ✅ **MCP servers** - TRON and BSC blockchain access configured in `~/.mcporter/mcporter.json`
- ✅ **Skills** - Pre-built workflows installed to your chosen location
- ✅ **Available components**: See [mcp-server-tron](https://github.com/bankofai/mcp-server-tron), [bnbchain-mcp](https://github.com/bnb-chain/bnbchain-mcp), and [skills repository](https://github.com/BofAI/skills)

**Note**: This installer uses `mcporter` (OpenClaw's official MCP manager) for configuration. Ensure OpenClaw is installed first.

## 🔐 Security

### TRON Wallet (agent-wallet)

mcp-server-tron uses **agent-wallet** for encrypted key storage. Private keys are encrypted at rest (Keystore V3: scrypt + AES-128-CTR) and never exposed in plaintext.

```bash
# Initialize wallet
npx @bankofai/agent-wallet init --dir ~/.agent-wallet
npx @bankofai/agent-wallet add --dir ~/.agent-wallet
npx @bankofai/agent-wallet list --dir ~/.agent-wallet
```

The installer will prompt for `AGENT_WALLET_DIR` and `AGENT_WALLET_PASSWORD` and save them to `~/.mcporter/mcporter.json`.

### BNB Chain

For bnbchain-mcp, credentials can be stored in the config file or via environment variables:
```bash
export PRIVATE_KEY="0x_your_private_key_here"
```

### Best Practices

- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on testnets (Nile for TRON, BSC Testnet for BSC) before using mainnet
- Secure config file: `chmod 600 ~/.mcporter/mcporter.json`

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on testnets (Nile for TRON, BSC Testnet for BSC) before interacting with mainnets.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
