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

- **x402-mcp** - MCP wrapper around the x402 CLI
  - Installed via `npx -y @bankofai/x402-mcp@2.6.0-beta.10`
  - Exposes `x402_status`, `x402_balance`, `x402_approve`, and `x402_pay`
  - Intended as the MCP alternative to the `x402-payment` skill

### 2. Skills

Pre-built workflows and tools from the published **skills repository**:

The installer clones [BofAI/skills](https://github.com/BofAI/skills) and installs skills from the pinned `v1.4.8` tag by default.

**Available Skills:**
- **sunswap** - SunSwap DEX trading skill for TRON token swaps
- **x402-payment** - Enables agent payments on TRON network (x402 protocol, with Gasfree support)
- **x402-payment-demo** - Demo of x402 payment protocol
- **ainft-skill** - Local AINFT balance and order queries

`x402-mcp` and the `x402-payment` / `x402-payment-demo` skills are intentionally mutually exclusive. Install one path or the other.

For complete documentation and usage instructions, see the [x402 repository](https://github.com/BofAI/x402).

### x402 Options

There are two supported x402 installation paths:

- **x402 skills**
  - Installs `x402-payment` and optionally `x402-payment-demo` from the published [BofAI/skills](https://github.com/BofAI/skills) repository.
  - Best when you want OpenClaw to use the hosted demo flow directly through skills.
  - The demo skill defaults to the hosted TRON/BSC demo service at `https://tn-x402-demo.bankofai.io`.
  - The skill installs `@bankofai/x402-mcp` as a private npm dependency inside the skill directory, but it does not require or install the `x402-mcp` MCP server.

- **x402-mcp**
  - Installs the MCP wrapper via `npx -y @bankofai/x402-mcp@2.6.0-beta.10`.
  - Exposes `x402_status`, `x402_balance`, `x402_approve`, and `x402_pay` as MCP tools.
  - Best when you want direct tool-based access instead of natural-language skills.
  - This is a separate MCP server install path, not a prerequisite for the skill path.

The hosted x402 demo endpoints currently used by the skill path are:

- `https://tn-x402-demo.bankofai.io/protected-nile`
- `https://tn-x402-demo.bankofai.io/protected-bsc-testnet`
- `https://tn-x402-demo.bankofai.io/protected-multi`

The BSC hosted demo is configured for public testnet stablecoins, not private project-only tokens:

- `USDT`
- `USDC`

Minimum wallet configuration for x402:

- TRON skill or MCP usage:
  - `TRON_PRIVATE_KEY`
  - optional `TRONGRID_API_KEY`
- EVM/BSC usage:
  - `PRIVATE_KEY` or `EVM_PRIVATE_KEY`
  - optional `BSC_TESTNET_RPC_URL`
  - optional `BSC_MAINNET_RPC_URL`

Typical OpenClaw skill prompts after installation:

- `demo x402-payment`
- `demo x402-payment on bsc-testnet`
- `pay with x402 url=https://tn-x402-demo.bankofai.io/protected-nile network=nile`

## 🛠 Installation

### Prerequisites
- **OpenClaw** (Your personal, open-source AI assistant) - [Install from here](https://github.com/openclaw)
- **Node.js** (v18+)
- **Python 3** (for configuration helpers)
- **Git** (for cloning the x402 repository when needed)
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

- ✅ **MCP servers** - TRON, BSC, optional AINFT merchant, and optional `x402-mcp` entries configured in `~/.mcporter/mcporter.json`
- ✅ **Skills** - Pre-built workflows installed to your chosen location
- ✅ **Available components**: See [mcp-server-tron](https://github.com/bankofai/mcp-server-tron), [bnbchain-mcp](https://github.com/bnb-chain/bnbchain-mcp), `ainft-merchant` (`https://ainft-agent.bankofai.io/mcp`), `x402-mcp` from npm, and [BofAI/skills](https://github.com/BofAI/skills)

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
