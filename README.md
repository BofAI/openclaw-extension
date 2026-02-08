# OpenClaw Extension

OpenClaw Extension is a suite of tools developed by **BankofAI** to empower AI Agents with financial sovereignty. It enables agents to hold wallets, execute transactions, and monetize services using the **x402 Protocol** (HTTP 402 Payment Required).

## 🚀 Mission

To build the "Central Bank" for the agent economy, ensuring every AI agent can:
- **Earn**: Accept payments for tasks and services via standard protocols.
- **Spend**: Pay for resources (computation, data, storage) autonomously.
- **Connect**: Facilitate direct Agent-to-Agent (A2A) financial activities and settlements.
- **Transact**: Interact with DeFi and smart contracts seamlessly.

## 📦 Core Components

This extension distributes the OpenClaw suite of tools tailored for TRON:

### Infrastructure (Prerequisites)
These foundational tools are installed to manage the agent ecosystem:

1.  **clawhub**: The **Skill Directory for OpenClaw**.
    - A registry where agents can discover new capabilities and tools.
    - Allows developers to publish and share agent skills.

2.  **mcporter**: The **MCP Manager**.
    - Simplifies the configuration and management of multiple MCP servers.
    - Handles environment variables and secure configuration injection.

### Agent Capabilities

1.  **x402-tron-payment (Payment Protocol)**
    This implements the **x402** protocol standard for the TRON Virtual Machine (TVM).
    - Enables "Pay-per-Request" models for agent APIs.
    - Allows agents to generate payment demands (invoices) and verify on-chain settlement before performing tasks.
    - **Benefit**: Turns any agent endpoint into a monetizable asset.

2.  **mcp-server-tron**
    A Model Context Protocol (MCP) server that gives LLMs direct access to the TRON blockchain.
    - **Capabilities**: Balance checks, transfers, smart contract interactions, resource estimation.

## 🛠 Installation

OpenClaw Extension provides a CLI installer to set up your environment quickly.

### Prerequisites
- **OpenClaw** (Your personal, open-source AI assistant)
- **Node.js** (v18+)
- **Python 3** (for configuration helpers)
- **TRON Wallet** (Private Key & API Key for TRON network interaction)

### Quick Start

Install from source:

```bash
./install.sh
```

Online install:

```bash
curl -fsSL https://raw.githubusercontent.com/bankofai/openclaw-extension/refs/heads/main/install.sh | bash
```

The interactive CLI will guide you through:
1.  Selecting desired skills (`x402-tron-payment`, etc.).
2.  Configuring the `mcp-server-tron`.
3.  Securely setting up your credentials.

## 🔐 Security

The tools require access to TRON private keys to sign transactions on behalf of the agent.
- Keys are stored locally in `$HOME/.mcporter/mcporter.json`.
- **Warning**: Ensure this file is secured (`chmod 600`) and never shared or committed to version control.
- We recommend using specific agent wallets with limited funds rather than your main personal wallet.

## Use at your own risk

Allowing AI agents to handle private keys directly involves substantial security risks. We advise using only small amounts of cryptocurrency and exercising caution. Despite the built-in safeguards, there is no guarantee that your assets are immune to loss. This extension is currently in an experimental stage and has not been subjected to rigorous testing. It is provided without any warranty or assumption of liability. Always validate your setup on a testnet (e.g., Nile) before interacting with the TRON mainnet.

## 🤝 Contributing

We welcome contributions! Please see the [OpenClaw](https://github.com/openclaw) organization for more details on the underlying technologies.
