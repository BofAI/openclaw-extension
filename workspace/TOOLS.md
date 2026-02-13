# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## 🌐 Web3 Tools (If Installed)

If you have blockchain capabilities (OpenClaw Extension), add your Web3-specific notes here:

```markdown
### Wallets

- Main wallet: T... (TRON mainnet)
- Test wallet: T... (Nile testnet)
- BSC wallet: 0x... (BSC mainnet)

### Preferred Networks

- Default: TRON mainnet
- Testing: Nile testnet

### Gas Preferences

- TRON: Keep 100+ TRX buffer
- BSC: Keep 0.01+ BNB buffer
- Warn if gas > $10 on Ethereum

### Skills Location

- Skills path: ~/.openclaw/skills/
- Frequently used: sunswap, 8004-skill, x402-payment
```

**Remember:** Never put private keys here. Only public addresses and preferences.

---

Add whatever helps you do your job. This is your cheat sheet.
