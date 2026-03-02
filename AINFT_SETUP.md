# AINFT Integration Guide

Quick guide to integrate AINFT AI models with OpenClaw.

## What is AINFT?

AINFT is an AI model provider on TRON that supports multiple models (GPT-5, Claude-4.5, Gemini-3) with crypto payment.

## 🚀 Quick Setup (One-Click Script)

The easiest way to configure AINFT:

```bash
bash setup_ainft.sh
```

The script will guide you through:
1. Mainnet configuration
2. Getting/entering your API key
3. Selecting models to enable
4. Setting default model (optional)
   - Default model choices are shown from the models you enabled in step 3
5. Automatic configuration update
6. OpenClaw restart

## Manual Setup

### Step 1: Get API Key

1. Visit AINFT website:
   - **Mainnet**: https://chat-dev.ainft.com/key

2. Create your API key

3. Deposit tokens to use the service:
   - **Mainnet**: `TNxh1UDWbzN8gMgfKQCSTjbB7Ugg7EuBDY`
   - Minimum: 1 TRX or 1 USDT/USDD

### Step 2: Configure OpenClaw

Edit your OpenClaw configuration:
```bash
vim ~/.openclaw/openclaw.json
```

Add AINFT provider configuration:

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "ainft": {
        "baseUrl": "https://chat-dev.ainft.com/webapi/",
        "apiKey": "YOUR_AINFT_API_KEY_HERE",
        "api": "openai-completions",
        "models": [
          {"id": "gpt-5.2", "name": "gpt-5.2"},
          {"id": "gpt-5-mini", "name": "gpt-5-mini"},
          {"id": "gpt-5-nano", "name": "gpt-5-nano"},
          {"id": "claude-opus-4.5", "name": "claude-opus-4.5"},
          {"id": "claude-sonnet-4.5", "name": "claude-sonnet-4.5"},
          {"id": "claude-haiku-4.5", "name": "claude-haiku-4.5"},
          {"id": "gemini-3-pro", "name": "gemini-3-pro"},
          {"id": "gemini-3-flash", "name": "gemini-3-flash"}
        ]
      }
    }
  }
}
```

### Step 3: Set Default Model (Optional)

To use AINFT models by default, add to your `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ainft/gpt-5-nano"
      }
    }
  }
}
```

### Step 4: Restart OpenClaw

```bash
openclaw gateway restart
```

## Available Models

| Model | Description | Use Case |
|-------|-------------|----------|
| gpt-5.2 | Most capable | Complex tasks |
| gpt-5-mini | Balanced | General use |
| gpt-5-nano | Fast & cheap | Simple tasks |
| claude-opus-4.5 | Most capable Claude | Analysis, coding |
| claude-sonnet-4.5 | Balanced Claude | General use |
| claude-haiku-4.5 | Fast Claude | Quick responses |
| gemini-3-pro | Most capable Gemini | Multimodal tasks |
| gemini-3-flash | Fast Gemini | Quick responses |

## Usage

Once configured, you can use AINFT models in OpenClaw:

```bash
# Use specific model
openclaw chat --model ainft/gpt-5-nano

# Or if set as default, just use normally
openclaw chat
```

## Environment

| Environment | Web | API BaseURL | Deposit Address |
|-------------|-----|-------------|-----------------|
| **Mainnet** | https://chat-dev.ainft.com/ | https://chat-dev.ainft.com/webapi/ | TNxh1UDWbzN8gMgfKQCSTjbB7Ugg7EuBDY |

## Troubleshooting

### "Invalid API key"
- Check your API key is correct
- Ensure you've deposited tokens to your account

### "Insufficient balance"
- Deposit more tokens to the deposit address
- Minimum: 1 TRX or 1 USDT/USDD

### Models not showing up
- Restart OpenClaw gateway: `openclaw gateway restart`
- Check configuration syntax in `openclaw.json`

## Resources

- **Full Documentation**: https://github.com/RudolphHuang/openclaw_doc
- **AINFT Mainnet**: https://chat-dev.ainft.com/

---

**Note**: AINFT uses crypto payment. Make sure to deposit tokens before using the service.
