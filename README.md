# OpenClaw Extension

OpenClaw Extension is a suite of tools developed by **BANK OF AI** to empower AI Agents with financial sovereignty. It enables agents to hold wallets, execute transactions, and monetize services using the **x402 Protocol** (HTTP 402 Payment Required).

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

- **BANK OF AI recharge MCP** - Remote BANK OF AI recharge MCP
  - Default remote endpoint: `https://recharge.bankofai.io/mcp`
  - Exposed through `mcporter` as `bankofai-recharge`
  - Intended for BANK OF AI recharge flows

### 2. Skills

Pre-built workflows and tools from the **[skills repository](https://github.com/BofAI/skills)**:

The installer clones the [skills repository](https://github.com/BofAI/skills) and lets you choose which skills to install during setup.
By default, it installs from the pinned skills tag `v1.4.12`. You can still override this with `GITHUB_BRANCH` when needed.

**Available Skills:**
- **sunswap** - SunSwap DEX trading skill for TRON token swaps
- **tronscan-skill** - TRON blockchain data lookup via the TronScan API
- **x402-payment** - Enables agent payments on TRON network (x402 protocol, with Gasfree support)
- **recharge-skill** - Local BANK OF AI balance/order queries plus recharge via remote MCP

For complete documentation and usage instructions, see the [skills repository](https://github.com/BofAI/skills).

## 🛠 Installation

### Prerequisites
- **OpenClaw** (Your personal, open-source AI assistant) - [Install from here](https://github.com/openclaw)
- **Node.js** (v18+)
- **Python 3** (for configuration helpers)
- **Git** (for cloning skills repository)
- **TRON Wallet** (Private Key & API Key for TRON network interaction)

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

- ✅ **MCP servers** - TRON, BSC, and optional BANK OF AI recharge MCP entries configured in `~/.mcporter/mcporter.json`
- ✅ **Skills** - Pre-built workflows installed to your chosen location
- ✅ **Available components**: See [mcp-server-tron](https://github.com/bankofai/mcp-server-tron), [bnbchain-mcp](https://github.com/bnb-chain/bnbchain-mcp), `bankofai-recharge` (`https://recharge.bankofai.io/mcp`), and [skills repository](https://github.com/BofAI/skills)

**Note**: This installer uses `mcporter` (OpenClaw's official MCP manager) for configuration. Ensure OpenClaw is installed first.

## 🔐 Security

### Credential Storage Options

The installer offers two methods for storing blockchain credentials:

**Option 1: Config File Storage**
- Keys stored in `~/.mcporter/mcporter.json`
- Convenient but less secure (plaintext)
- **Important**: Secure the file with `chmod 600 ~/.mcporter/mcporter.json`
- Never share or commit this file to version control

**Option 2: Environment Variables (Recommended)**
- Keys read from shell environment
- More secure, not stored in config files
- Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
  ```bash
  # For TRON
  export TRON_PRIVATE_KEY="your_private_key_here"
  export TRONGRID_API_KEY="your_api_key_here"
  
  # For BSC/EVM chains
  export PRIVATE_KEY="0x_your_private_key_here"
  ```
- Restart your shell or run `source ~/.zshrc` after adding

**Option 3: Gasfree API Credentials (for x402-payment)**
- Used for gasless transactions on TRON via the Gasfree service
- Stored in `~/.x402-config.json`
- The installer will prompt for `GASFREE_API_KEY` and `GASFREE_API_SECRET` when installing the x402-payment skill
- Secure the file with `chmod 600 ~/.x402-config.json`
- Manual configuration:
  ```json
  {
    "gasfree_api_key": "YOUR_KEY",
    "gasfree_api_secret": "YOUR_SECRET"
  }
  ```

### Best Practices

- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on testnets (Nile for TRON, BSC Testnet for BSC) before using mainnet
- Do not allow AI agents to scan files containing private keys

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on testnets (Nile for TRON, BSC Testnet for BSC) before interacting with mainnets.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
