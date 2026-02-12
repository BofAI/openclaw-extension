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

- **[bnbchain-mcp](https://github.com/bnb-chain/mcp-server)** - BNB Chain official MCP server
  - Multi-chain support: BSC, opBNB, Ethereum, Greenfield
  - Wallet operations, smart contracts, token transfers
  - Cross-chain capabilities

### 2. Skills

Pre-built workflows and tools from the **[skills repository](https://github.com/bankofai/skills)**:

For the complete list of available skills and their documentation, see the [skills repository](https://github.com/bankofai/skills).

The installer will let you select which skills to install during setup.

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
curl -fsSL https://raw.githubusercontent.com/bankofai/openclaw-extension/refs/heads/main/install.sh | bash
```

Or from source:

```bash
git clone https://github.com/bankofai/openclaw-extension.git
cd openclaw-extension
./install.sh
```

### What Gets Installed

- ✅ **MCP servers** - TRON and BSC blockchain access configured in `~/.mcporter/mcporter.json`
- ✅ **Skills** - Pre-built workflows installed to your chosen location
- ✅ **Available components**: See [mcp-server-tron](https://github.com/bankofai/mcp-server-tron), [bnbchain-mcp](https://github.com/bnb-chain/mcp-server), and [skills repository](https://github.com/bankofai/skills)

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

### Best Practices

- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on testnets (Nile for TRON, BSC Testnet for BSC) before using mainnet
- Do not allow AI agents to scan files containing private keys

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on testnets (Nile for TRON, BSC Testnet for BSC) before interacting with mainnets.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
