# Security Policy

## Scope

This repository installs and configures MCP servers, skills, and optional payment-related credentials.
Treat all blockchain private keys, API secrets, and local config files as sensitive.

Sensitive values include:

- `TRON_PRIVATE_KEY`
- `TRONGRID_API_KEY`
- `PRIVATE_KEY`
- `GASFREE_API_KEY`
- `GASFREE_API_SECRET`
- any secret written to `~/.mcporter/mcporter.json`
- any secret written to `~/.x402-config.json`

## Reporting Vulnerabilities

Do not open a public GitHub issue for:

- private key exposure
- auth bypass
- remote credential leakage
- unsafe file-permission behavior
- payment signing or settlement vulnerabilities

Report security issues privately to the maintainers through the organization contact channel used for operational support.

When reporting, include:

- affected version or commit
- reproduction steps
- impact
- whether any credential or wallet was exposed

## Operational Guidance

- Use dedicated low-balance agent wallets.
- Never commit secrets or personal wallets.
- Restrict permissions on local config files:
  - `chmod 600 ~/.mcporter/mcporter.json`
  - `chmod 600 ~/.x402-config.json`
- Prefer environment variables over plaintext config when possible.
- Validate on testnets before using mainnet credentials.
