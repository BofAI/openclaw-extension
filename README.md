# OpenClaw Extension

OpenClaw Extension is a suite of tools developed by **BankofAI** to empower AI Agents with financial sovereignty. It enables agents to hold wallets, execute transactions, and monetize services using the **x402 Protocol** (HTTP 402 Payment Required).

## 🚀 Mission

To build the "Central Bank" for the agent economy, ensuring every AI agent can:
- **Earn**: Accept payments for tasks and services via standard protocols.
- **Spend**: Pay for resources (computation, data, storage) autonomously.
- **Connect**: Facilitate direct Agent-to-Agent (A2A) financial activities and settlements.
- **Transact**: Interact with DeFi and smart contracts seamlessly.

## 📦 Core Components

This extension provides tools for TRON blockchain interaction:

### MCP Server

**mcp-server-tron**: A Model Context Protocol (MCP) server that gives AI agents direct access to the TRON blockchain.
- **Capabilities**: Balance checks, transfers, smart contract interactions, resource estimation, token swaps

### Skills from GitHub

The installer automatically fetches skills from the [skills-tron](https://github.com/bankofai/skills-tron) repository:

1.  **sunswap** - SunSwap DEX trading skill for TRON token swaps
    - Multi-version pool routing (V1/V2/V3/PSM)
    - Price quotes with slippage protection
    - Token approval management

2.  **x402_tron_payment** - Enables agent payments on TRON network (x402 protocol)
    - Pay-per-request models for agent APIs
    - Payment verification before task execution

3.  **x402_tron_payment_demo** - Demo of x402 payment protocol

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

### Installation Steps

The interactive installer will guide you through:

**Step 1: Configure MCP Server**
- Set up `mcp-server-tron` with your credentials
- **Choose credential storage method:**
  - **Option 1**: Save in config file (`~/.mcporter/mcporter.json`)
    - Convenient but less secure (plaintext storage)
  - **Option 2**: Use environment variables (Recommended)
    - More secure, keys read from shell environment
    - Add to `~/.zshrc` or `~/.bashrc`:
      ```bash
      export TRON_PRIVATE_KEY="your_private_key_here"
      export TRONGRID_API_KEY="your_api_key_here"
      ```

**Step 2: Install Skills from GitHub**
- Automatically clones [skills-tron](https://github.com/bankofai/skills-tron) repository
- Interactive multi-select menu (Space to toggle, Enter to confirm)
- Choose installation location:
  - User-level: `~/.openclaw/skills/` (available to all workspaces)
  - Workspace-level: `.openclaw/skills/` (current workspace only)
  - Custom path

### What Gets Installed

- ✅ **MCP server configuration** - `~/.mcporter/mcporter.json`
- ✅ **Skills** - Installed to your chosen location
- ✅ **Available skills**: sunswap, x402_tron_payment, x402_tron_payment_demo

**Note**: This installer uses `mcporter` (OpenClaw's official MCP manager) for configuration. Ensure OpenClaw is installed first.

## 🔐 Security

### Credential Storage Options

The installer offers two methods for storing TRON credentials:

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
  export TRON_PRIVATE_KEY="your_private_key_here"
  export TRONGRID_API_KEY="your_api_key_here"
  ```
- Restart your shell or run `source ~/.zshrc` after adding

### Best Practices

- Use dedicated agent wallets with limited funds
- Never use your main personal wallet
- Test on Nile testnet before using mainnet
- Do not allow AI agents to scan files containing private keys

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on a testnet (e.g., Nile) before interacting with the TRON mainnet.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
