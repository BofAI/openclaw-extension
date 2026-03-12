# Changelog

All notable changes to **OpenClaw Extension** are documented in this file.

This project follows Semantic Versioning.

## [1.1.0] - 2026-03-12

### Added
- Gasfree API support: `install.sh` now supports configuring `GASFREE_API_KEY` and `GASFREE_API_SECRET` for the `x402-payment` skill
- New config file: `~/.x402-config.json` for storing Gasfree credentials
- Skills branch selection: the installer now supports a `GITHUB_BRANCH` environment variable and defaults to `v1.4.0`

### Changed
- Default skills version updated to `v1.4.0`
- README reorganized into a clearer usage-first structure

### Fixed
- Resolved issues in the AINFT merchant setup and configuration flow inside `install.sh`

## [1.0.3] - 2026-03-09

### Added
- `install.sh` can register `ainft-merchant` in `~/.mcporter/mcporter.json`
- `RELEASE_NOTE.md` was added and expanded

### Changed
- Reorganized the README structure
- Narrowed the documentation focus to:
  - how to install the extension
  - how to use skills
  - which platforms are compatible
  - the boundary between the local AINFT skill and the remote merchant MCP
- Simplified AINFT-related documentation to avoid mixing provider setup with installer docs

## [1.0.2] - 2026-02-09

### Added
- Rewrote `install.sh` to handle MCP server and skills installation in one flow
- Added two credential storage options:
  - config file
  - environment variables
- Added direct cloning and installation from [BofAI/skills](https://github.com/BofAI/skills)
- Added support for installing common skills:
  - `sunswap`
  - `8004-skill`
  - `x402-payment`
  - `x402-payment-demo`

### Changed
- Removed dependency on the previous skill distribution path
- Improved installer interaction flow
- Uses OpenClaw's official `mcporter` for MCP server configuration

### Security
- Environment variables are now the recommended credential storage method
- Strengthened warnings around private key and config-file handling

## [1.0.1] - 2026-02-06

### x402-payment Skill
- Added `TRON_GRID_API_KEY` support to reduce TronGrid 429 issues
- Upgraded `@bankofai/x402-tron` to `v0.1.6`
- Switched to `ExactTronClientMechanism` to align with the newer protocol implementation

## [1.0.0] - 2026-02-04

### Initial Release

First public release.

### Core Capabilities

- `mcp-server-tron`
  - TRON chain queries, transfers, and contract calls
- `x402-payment`
  - HTTP 402 / x402 payment capability
- `install.sh`
  - interactive MCP server and skills installation
- multi-network support
  - Mainnet
  - Nile
  - Shasta
