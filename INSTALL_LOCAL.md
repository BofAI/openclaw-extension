# Local Installation Guide

Install TRON skills from your local directory to OpenClaw.

## Quick Start

```bash
# Navigate to skills directory
cd skills

# Run the local installer
./install_local.sh
```

## What This Does

The local installer:
1. ✅ Scans the current directory for available skills
2. ✅ Lets you select which skills to install
3. ✅ Lets you choose installation location
4. ✅ Copies skills to OpenClaw
5. ✅ Installs npm dependencies automatically
6. ✅ Provides setup instructions

## Differences from Remote Installer

| Feature | Remote (`openclaw-extension/install.sh`) | Local (`install_local.sh`) |
|---------|------------------------------------------|----------------------------|
| Source | GitHub repository | Local directory |
| MCP Server | ✅ Configures | ❌ Skips |
| Skills | Downloads from GitHub | Copies from local |
| Use Case | End users | Developers/Testing |

## Installation Locations

### Option 1: User-level (Recommended)
```
~/.openclaw/skills/
```
- Available to all OpenClaw workspaces
- Persists across projects

### Option 2: Workspace-level
```
.openclaw/skills/
```
- Only available in current workspace
- Project-specific skills

### Option 3: Custom path
- Specify any directory
- Full control over location

## Usage Example

```bash
$ cd skills
$ ./install_local.sh

  🦞 Skills Local Installer
  TRON agents: Low fees, high speeds, zero excuses.

Skills Installation from Local Directory
Source: /Users/you/code/skills

? Select skills to install: (Space:toggle, Enter:confirm)
  ❯ [x] sunswap - SunSwap DEX trading skill for TRON token swaps
    [x] 8004-skill - 8004 Trustless Agents - Register, discover...
    [x] x402-payment - Enables agent payments on TRON network
    [ ] x402-payment-demo - Demo of x402 payment protocol

Select skills installation location:
  1) User-level (~/.openclaw/skills/) [Recommended]
  2) Workspace-level (.openclaw/skills/)
  3) Custom path

? Enter choice (1-3, default: 1): 1
→ Installing to: /Users/you/.openclaw/skills

Installing skills...

Installing sunswap...
✓ sunswap installed successfully

Installing 8004-skill...
  Installing npm dependencies...
✓ 8004-skill installed successfully

═══════════════════════════════════════
  Installation Complete!
═══════════════════════════════════════

✓ Installed skills:
  • sunswap
  • 8004-skill
  Location: /Users/you/.openclaw/skills

Next steps:

  1. Restart OpenClaw to load new skills
     • Close OpenClaw completely
     • Reopen OpenClaw

  2. Configure private key (for write operations):
     # Option 1: Environment variable
     export TRON_PRIVATE_KEY="your_private_key"

     # Option 2: File storage
     mkdir -p ~/.clawdbot/wallets
     echo "your_key" > ~/.clawdbot/wallets/.deployer_pk
     chmod 600 ~/.clawdbot/wallets/.deployer_pk

  3. Test the skills:
     "Read the sunswap skill and help me swap 100 USDT to TRX"
     "Read the 8004-skill and register my AI agent on TRON"

  📝 8004 Setup:
     cd /Users/you/.openclaw/skills/8004-skill
     npm install
     node scripts/test-key-loading.js  # Test configuration
```

## For Developers

### Testing Local Changes

1. Make changes to skills in `skills/`
2. Run `./install_local.sh`
3. Select the modified skill
4. Overwrite when prompted
5. Restart OpenClaw to test

### Rapid Development Workflow

```bash
# 1. Edit skill
vim 8004-skill/SKILL.md

# 2. Reinstall
./install_local.sh
# Select 8004-skill, overwrite: y

# 3. Test in OpenClaw
# Restart OpenClaw and test the changes
```

## Troubleshooting

### "No skills found"
```bash
# Make sure you're in the skills directory
pwd
# Should show: /path/to/skills

# Check for SKILL.md files
ls */SKILL.md
```

### "Permission denied"
```bash
# Make script executable
chmod +x install_local.sh
```

### "npm install failed"
```bash
# Install manually
cd ~/.openclaw/skills/8004-skill
npm install
```

### Skills not showing in OpenClaw
1. Verify installation location:
   ```bash
   ls -la ~/.openclaw/skills/
   ```
2. Check SKILL.md exists:
   ```bash
   cat ~/.openclaw/skills/8004-skill/SKILL.md
   ```
3. Restart OpenClaw completely

## Uninstalling Skills

```bash
# Remove from user-level
rm -rf ~/.openclaw/skills/8004-skill

# Remove from workspace-level
rm -rf .openclaw/skills/8004-skill
```

## Comparison with Remote Install

### Use Remote Install When:
- ✅ You're an end user
- ✅ You want the latest stable version
- ✅ You need MCP server configuration
- ✅ You don't have the source code

### Use Local Install When:
- ✅ You're developing skills
- ✅ You're testing local changes
- ✅ You have the source code locally
- ✅ You want to customize skills
- ✅ MCP server is already configured

## Advanced Usage

### Install to Multiple Locations

```bash
# Install to user-level
./install_local.sh
# Choose option 1

# Install to workspace-level
./install_local.sh
# Choose option 2
```

### Selective Installation

```bash
# Only install specific skills
./install_local.sh
# Uncheck unwanted skills with Space
```

### Custom Installation Path

```bash
./install_local.sh
# Choose option 3
# Enter: /custom/path/to/skills
```

## Script Features

- ✅ Interactive multiselect menu
- ✅ Automatic npm dependency installation
- ✅ Overwrite protection with confirmation
- ✅ Colored output for better readability
- ✅ Skill description auto-detection
- ✅ Post-install instructions
- ✅ Error handling

## Requirements

- Bash shell
- OpenClaw installed (optional, warning only)
- npm (for skills with dependencies)

## Support

If you encounter issues:

1. Check you're in the correct directory: `pwd`
2. Verify script permissions: `ls -la install_local.sh`
3. Check OpenClaw installation: `ls -la ~/.openclaw/`
4. See main [README.md](README.md) for more help

---

**For end users**: Use `openclaw-extension/install.sh` instead  
**For developers**: Use this `install_local.sh` for rapid testing
