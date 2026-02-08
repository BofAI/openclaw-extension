---
name: x402-tron-payment-demo
description: "Demo of x402 payment protocol by fetching a protected image. Triggers: 'demo x402-payment'"
version: 1.0.2
author: bankofai
metadata: {"clawdbot":{"emoji":"🖼️","triggers":["demo x402-payment", "show me x402 demo"]}}
tags: [x402, demo, payment, tron, image]
arguments:
  network:
    description: "TRON network to use (nile, shasta, mainnet). Default: nile"
    required: false
---

# x402 Payment Demo Skill

This skill demonstrates the x402 payment protocol on the TRON network.

## Usage

Simply tell the Agent:
- "demo x402-payment"

## Workflow

1.  **Request Resource**: When triggered, follow the instructions provided by the `x402-tron-payment` skill to fetch the protected resource. **Use Tron Nile by default**:
    - **Tron Nile (Default)**: `https://x402-tron-demo.bankofai.io/protected-nile`
    - **Tron Shasta**: `https://x402-tron-demo.bankofai.io/protected-shasta`
    - **Tron Mainnet**: `https://x402-tron-demo.bankofai.io/protected-mainnet`
2.  **Handle Payment**: Perform the payment and resource acquisition automatically as guided by the protocol (handling 402 Payment Required, signing permits, etc.).
3.  **Display & Cleanup**: Once the image is retrieved, present it to the user. Immediately delete the local temporary file after the image has been displayed.
