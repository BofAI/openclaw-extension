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

- **AINFT merchant MCP** - Remote AINFT recharge MCP
  - Default remote endpoint: `https://ainft-agent.bankofai.io/mcp`
  - Exposed through `mcporter` as `ainft-merchant`
  - Intended for AINFT recharge flows

### 2. Skills

Pre-built workflows and tools from the **[skills repository](https://github.com/BofAI/skills)**:

The installer clones the [skills repository](https://github.com/BofAI/skills) and lets you choose which skills to install during setup.
By default, it installs from the pinned skills tag `v1.4.12`. You can still override this with `GITHUB_BRANCH` when needed.

**Available Skills:**
- **sunswap** - SunSwap DEX trading skill for TRON token swaps
- **tronscan-skill** - TRON blockchain data lookup via the TronScan API
- **x402-payment** - Enables agent payments on TRON network (x402 protocol, with Gasfree support)
- **ainft-skill** - Local AINFT balance/order queries plus TRC20 top-up via remote MCP

For complete documentation and usage instructions, see the [skills repository](https://github.com/BofAI/skills).

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

- ✅ **MCP servers** - TRON, BSC, and optional AINFT merchant MCP entries configured in `~/.mcporter/mcporter.json`
- ✅ **Skills** - Pre-built workflows installed to your chosen location
- ✅ **Available components**: See [mcp-server-tron](https://github.com/bankofai/mcp-server-tron), [bnbchain-mcp](https://github.com/bnb-chain/bnbchain-mcp), `ainft-merchant` (`https://ainft-agent.bankofai.io/mcp`), and [skills repository](https://github.com/BofAI/skills)

**Note**: This installer uses `mcporter` (OpenClaw's official MCP manager) for configuration. Ensure OpenClaw is installed first.

## 🔐 Security

### Credential Storage Options

The installer offers five ways to configure blockchain credentials, depending on the component:

**Option 1: Agent Wallet Local Mode (Most Secure — Recommended for x402 skills and TRON MCP)**
- Private keys encrypted at rest using a master password (Keystore V3 / scrypt)
- Keys never appear as plaintext environment variables
- Managed with the [`@bankofai/agent-wallet`](https://www.npmjs.com/package/@bankofai/agent-wallet) CLI
- Supported by:
  - `x402-payment` skill
  - `mcp-server-tron` (uses the active TRON wallet)
- The installer guides you through setup (Step 3: Agent Wallet Setup)
- Quick start:
  ```bash
  npm install -g @bankofai/agent-wallet
  agent-wallet start
  ```
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
  # export AGENT_WALLET_DIR="~/.agent-wallet"      # optional
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

**Option 2: Agent Wallet Private Key Mode**
- Uses the same `@bankofai/agent-wallet` SDK without a local encrypted keystore
- Suitable for `x402-payment` when you want a single wallet from environment variables
- Enabled when `AGENT_WALLET_PASSWORD` is **not** set and exactly one of the following is provided:
  - `AGENT_WALLET_PRIVATE_KEY`
  - `AGENT_WALLET_MNEMONIC`
- Optional:
  - `AGENT_WALLET_MNEMONIC_ACCOUNT_INDEX="0"`
- Example:
  ```bash
  export AGENT_WALLET_PRIVATE_KEY="your_private_key_here"
  # or
  export AGENT_WALLET_MNEMONIC="word1 word2 ..."
  export AGENT_WALLET_MNEMONIC_ACCOUNT_INDEX="0"
  ```

**Option 3: Environment Variables**
- Keys read from shell environment, not stored in config files
- Suitable for MCP servers such as `mcp-server-tron` and `bnbchain-mcp`
- Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
  ```bash
  # For TRON
  export TRON_PRIVATE_KEY="your_private_key_here"
  export TRONGRID_API_KEY="your_api_key_here"
  
  # For BSC/EVM chains
  export PRIVATE_KEY="0x_your_private_key_here"
  ```
- Restart your shell or run `source ~/.zshrc` after adding

**Option 4: Config File Storage**
- Keys stored in `~/.mcporter/mcporter.json`
- Convenient but less secure (plaintext)
- **Important**: Secure the file with `chmod 600 ~/.mcporter/mcporter.json`
- Never share or commit this file to version control

### Switching Between Private Key and Agent Wallet

For both `x402-payment` and `mcp-server-tron`:
- Agent Wallet local mode is enabled when `AGENT_WALLET_PASSWORD` is set
- Agent Wallet private key mode uses `AGENT_WALLET_PRIVATE_KEY` or `AGENT_WALLET_MNEMONIC`
- Legacy MCP environment/config mode uses `TRON_PRIVATE_KEY` or config-file credentials
- When local mode and private key mode both exist, local mode takes priority
- Users do **not** need to configure any extra source-selection variable

Wallet selection differs slightly:
- `x402-payment` uses `TRON_AGENT_WALLET_NAME` and `EVM_AGENT_WALLET_NAME` to select which wallet to use
- `mcp-server-tron` follows the active wallet in `agent-wallet`, so switching is done with `agent-wallet use <id>`

**Option 5: Gasfree API Credentials (for x402-payment)**
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

- **Prefer agent wallet** for x402-payment and `mcp-server-tron` — keys are encrypted, never exposed in config files
- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on testnets (Nile for TRON, BSC Testnet for BSC) before using mainnet
- Do not allow AI agents to scan files containing private keys

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on testnets (Nile for TRON, BSC Testnet for BSC) before interacting with mainnets.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
