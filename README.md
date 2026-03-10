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
- **TRON Wallet** (Private Key & API Key for TRON network interaction)
- **[@bankofai/agent-wallet](https://www.npmjs.com/package/@bankofai/agent-wallet)** (optional, recommended for secure key management)

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

### Credential Storage Options

The installer offers three methods for storing blockchain credentials:

**Option 1: Agent Wallet (Most Secure — Recommended for x402 skills and TRON MCP)**
- Private keys encrypted at rest using a master password (Keystore V3 / scrypt)
- Keys never appear as plaintext environment variables
- Managed with the [`@bankofai/agent-wallet`](https://www.npmjs.com/package/@bankofai/agent-wallet) CLI
- Supported by:
  - `x402-payment` skill
  - `mcp-server-tron` (uses the active TRON wallet)
- The installer guides you through setup (Step 3: Agent Wallet Setup)
- Manual setup:
  ```bash
  npm install -g @bankofai/agent-wallet
  agent-wallet init
  agent-wallet add        # choose tron_local or evm_local
  agent-wallet list       # confirm wallet name
  ```
- Configure for x402-payment skill:
  ```bash
  export TRON_AGENT_WALLET_NAME="my-tron-wallet"
  export AGENT_WALLET_PASSWORD="your-master-password"
  # export EVM_AGENT_WALLET_NAME="my-evm-wallet"   # optional
  ```
- Configure for `mcp-server-tron`:
  ```bash
  export AGENT_WALLET_PASSWORD="your-master-password"
  # export AGENT_WALLET_DIR="~/.agent-wallet"      # optional
  export TRONGRID_API_KEY="your_api_key_here"      # recommended for mainnet
  ```
- `mcp-server-tron` uses the **active** wallet from `agent-wallet`. Switch it with:
  ```bash
  agent-wallet list
  agent-wallet use my-tron-wallet
  ```
- See [Agent Wallet CLI Guide](https://www.npmjs.com/package/@bankofai/agent-wallet) for full documentation

**Option 2: Environment Variables**
- Keys read from shell environment, not stored in config files
- Suitable for MCP servers (mcp-server-tron, bnbchain-mcp)
- Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
  ```bash
  # For TRON
  export TRON_PRIVATE_KEY="your_private_key_here"
  export TRONGRID_API_KEY="your_api_key_here"
  
  # For BSC/EVM chains
  export PRIVATE_KEY="0x_your_private_key_here"
  ```
- Restart your shell or run `source ~/.zshrc` after adding

**Option 3: Config File Storage**
- Keys stored in `~/.mcporter/mcporter.json`
- Convenient but less secure (plaintext)
- **Important**: Secure the file with `chmod 600 ~/.mcporter/mcporter.json`
- Never share or commit this file to version control

### Switching Between Private Key and Agent Wallet

For both `x402-payment` and `mcp-server-tron`:
- Agent Wallet mode is enabled when `AGENT_WALLET_PASSWORD` is set
- Legacy mode uses plaintext private key configuration
- When Agent Wallet and legacy key config both exist, Agent Wallet takes priority
- Users do **not** need to configure any extra source-selection variable

Wallet selection differs slightly:
- `x402-payment` uses `TRON_AGENT_WALLET_NAME` and `EVM_AGENT_WALLET_NAME` to select which wallet to use
- `mcp-server-tron` follows the active wallet in `agent-wallet`, so switching is done with `agent-wallet use <id>`

### Best Practices

- **Prefer agent wallet** for x402-payment and `mcp-server-tron` — keys are encrypted, never exposed in config files
- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on testnets (Nile for TRON, BSC Testnet for BSC) before using mainnet
- Do not allow AI agents to scan files containing private keys

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on testnets (Nile for TRON, BSC Testnet for BSC) before interacting with mainnets.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
