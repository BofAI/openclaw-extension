# OpenClaw Extension

OpenClaw Extension is a BankOfAI toolkit for connecting AI agents to MCP servers and reusable skills.  
It does not replace the AI agent itself. Instead, it installs and wires the components that let platforms such as OpenClaw, ClawdCode, OpenCode, and other MCP-compatible agents gain:

- blockchain interaction
- reusable skill workflows
- x402 payment support
- AINFT query and recharge capabilities

## Overview

OpenClaw Extension has two main jobs:

1. install and configure common MCP servers
2. install and connect the skills repository

After setup, an AI agent can go beyond plain conversation and use:

- blockchain tools
- predefined workflows
- paid agent endpoints via x402
- AINFT-related query and recharge flows

## How It Works

The model is straightforward:

1. the AI agent understands the user request
2. MCP servers provide executable tools
3. skills provide task instructions and workflow rules
4. OpenClaw Extension installs and connects these parts in the local environment

In short:

- a `Skill` is the instruction layer
- an `MCP Server` is the tool layer
- `OpenClaw Extension` is the installer and integration layer

## How To Use Skills

Skills can be used with OpenClaw, ClawdCode, OpenCode, and other AI agents that support MCP (Model Context Protocol).  
This document uses OpenClaw as the primary example.

Before starting, make sure you have:

- installed OpenClaw
- installed or downloaded OpenClaw Extension
- completed the base MCP server configuration

## Compatible Platforms

Skills work with MCP-compatible AI agent platforms, including:

- `OpenClaw`
- `ClawdCode`
- `OpenCode`
- other AI agents that support MCP

## Quick Installation Example

Using OpenClaw, the minimal flow is:

1. install OpenClaw
2. install OpenClaw Extension

```bash
curl -fsSL https://raw.githubusercontent.com/BofAI/openclaw-extension/refs/heads/main/install.sh | bash
```

If you prefer to run from source:

```bash
git clone https://github.com/BofAI/openclaw-extension.git
cd openclaw-extension
./install.sh
```

## Included Components

### MCP Servers

- [`mcp-server-tron`](https://github.com/bankofai/mcp-server-tron)
  - TRON chain queries, transfers, and contract calls
  - supports Mainnet / Nile / Shasta
- [`bnbchain-mcp`](https://github.com/bnb-chain/bnbchain-mcp)
  - BSC / opBNB / Ethereum / Greenfield and related networks
- `ainft-merchant`
  - remote MCP endpoint: `https://ainft-agent.bankofai.io/mcp`
  - used for AINFT recharge flows

### Skills

The installer pulls the skills repository from `https://github.com/BofAI/skills`.  
The default skills branch can be controlled with `GITHUB_BRANCH`, and currently defaults to `v1.4.0`.

Common skills include:

- `sunswap`
- `8004-skill`
- `x402-payment`
- `x402-payment-demo`
- `ainft-skill`

## How To Use A Skill

You do not need to write complex code. In most cases, you just ask the AI agent in natural language.

### Option 1: Explicit Invocation

If you already know which skill you want, tell the AI agent to read the exact `SKILL.md`.

Example:

```text
Please read skills/sunswap/SKILL.md and help me check how much TRX I can get for 100 USDT.
```

### Option 2: Implicit Trigger

If the skill is already installed, you can simply describe the task and let the AI agent pick the right skill.

Example:

```text
Help me check how much TRX 100 USDT can get on SunSwap right now.
```

## What The Installer Configures

`install.sh` mainly handles two areas:

1. MCP server configuration
2. skills repository cloning and installation

Typical results after installation:

- MCP server entries written to `~/.mcporter/mcporter.json`
- local skills directory created or updated
- optional remote `ainft-merchant` MCP configuration
- optional Gasfree credentials for `x402-payment`

## Security Notes

The installer currently supports three common credential patterns.

### Option 1: `mcporter` Configuration File

- stored in `~/.mcporter/mcporter.json`
- convenient for MCP server credentials
- local plaintext storage, so file permissions matter

Recommended:

```bash
chmod 600 ~/.mcporter/mcporter.json
```

### Option 2: Environment Variables

Environment variables are the recommended way to keep private keys and API keys out of configuration files.

Example:

```bash
# TRON
export TRON_PRIVATE_KEY="your_private_key_here"
export TRONGRID_API_KEY="your_api_key_here"

# BSC / EVM
export PRIVATE_KEY="0x_your_private_key_here"
```

### Option 3: Gasfree API Credentials

`x402-payment` now supports gasless transactions on TRON through the Gasfree API.

- stored in `~/.x402-config.json`
- the installer can prompt for:
  - `GASFREE_API_KEY`
  - `GASFREE_API_SECRET`

Recommended:

```bash
chmod 600 ~/.x402-config.json
```

Best practices:

- use dedicated agent wallets
- do not use your personal main wallet
- validate on testnets before mainnet use
- do not let AI agents read directories that contain private keys or API secrets

## AINFT Notes

AINFT support is intentionally split into two parts:

- `ainft-skill`
  - local query capability
  - used for balance and order reads
- `ainft-merchant`
  - remote MCP capability
  - used for recharge-related flows

These should remain separate. The local query skill and the remote merchant MCP solve different problems.

## Using Other AI Agent Platforms

If you are using ClawdCode, OpenCode, or another MCP-compatible platform:

1. install your AI agent
2. configure MCP servers manually according to that platform
3. clone the skills repository locally

```bash
git clone https://github.com/BofAI/skills.git
```

4. point the AI agent to the skills directory, or explicitly reference the needed `SKILL.md`

## Release Information

- release notes: [RELEASE_NOTE.md](RELEASE_NOTE.md)
- changelog: [CHANGELOG.md](CHANGELOG.md)
- security policy: [SECURITY.md](SECURITY.md)
- contributing guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- license: [LICENSE](LICENSE)
