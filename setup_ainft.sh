#!/bin/bash

# AINFT Setup Script for OpenClaw
# Quickly configure AINFT AI models in OpenClaw

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
   _    ___ _   _ _____ _____ 
  / \  |_ _| \ | |  ___|_   _|
 / _ \  | ||  \| | |_    | |  
/ ___ \ | || |\  |  _|   | |  
/_/   \_\___|_| \_|_|     |_|  
                                
OpenClaw Integration Setup
EOF
echo -e "${NC}"

CONFIG_FILE="$HOME/.openclaw/openclaw.json"

# Check if OpenClaw is installed
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: OpenClaw configuration not found at $CONFIG_FILE${NC}"
    echo -e "${YELLOW}Please install OpenClaw first: https://github.com/openclaw${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found OpenClaw configuration${NC}"
echo ""

# Step 1: Mainnet configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1: Mainnet Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ENVIRONMENT="mainnet"
BASE_URL="https://chat.ainft.com/webapi/"
WEB_URL="https://chat.ainft.com"
DEPOSIT_ADDRESS="TNxh1UDWbzN8gMgfKQCSTjbB7Ugg7EuBDY"

echo ""
echo -e "${GREEN}✅ Environment fixed: $ENVIRONMENT${NC}"
echo -e "   Base URL: $BASE_URL"
echo ""

# Step 2: Get API Key
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2: Enter API Key${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 Before running this script, please:${NC}"
echo "1. Visit: ${WEB_URL}/key"
echo "2. Create an API key"
echo "3. Deposit tokens to: ${DEPOSIT_ADDRESS}"
echo "   (Minimum: 1 TRX or 1 USDT/USDD)"
echo "4. API key input below is hidden (no echo)"
echo ""
read -s -p "Enter your AINFT API key: " API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ API key cannot be empty. Exiting.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ API key received${NC}"
echo ""

# Step 3: Select models
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Select Models${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1) All models (GPT-5, Claude-4.5, Gemini-3)"
echo "2) GPT-5 series only"
echo "3) Claude-4.5 series only"
echo "4) Gemini-3 series only"
echo ""
read -p "Select models [1-4]: " model_choice

case $model_choice in
    1)
        MODELS='[
          {"id": "gpt-5.2", "name": "gpt-5.2"},
          {"id": "gpt-5-mini", "name": "gpt-5-mini"},
          {"id": "gpt-5-nano", "name": "gpt-5-nano"},
          {"id": "claude-opus-4.5", "name": "claude-opus-4.5"},
          {"id": "claude-sonnet-4.5", "name": "claude-sonnet-4.5"},
          {"id": "claude-haiku-4.5", "name": "claude-haiku-4.5"},
          {"id": "gemini-3-pro", "name": "gemini-3-pro"},
          {"id": "gemini-3-flash", "name": "gemini-3-flash"}
        ]'
        ;;
    2)
        MODELS='[
          {"id": "gpt-5.2", "name": "gpt-5.2"},
          {"id": "gpt-5-mini", "name": "gpt-5-mini"},
          {"id": "gpt-5-nano", "name": "gpt-5-nano"}
        ]'
        ;;
    3)
        MODELS='[
          {"id": "claude-opus-4.5", "name": "claude-opus-4.5"},
          {"id": "claude-sonnet-4.5", "name": "claude-sonnet-4.5"},
          {"id": "claude-haiku-4.5", "name": "claude-haiku-4.5"}
        ]'
        ;;
    4)
        MODELS='[
          {"id": "gemini-3-pro", "name": "gemini-3-pro"},
          {"id": "gemini-3-flash", "name": "gemini-3-flash"}
        ]'
        ;;
    *)
        echo -e "${RED}Invalid choice. Using all models.${NC}"
        MODELS='[
          {"id": "gpt-5.2", "name": "gpt-5.2"},
          {"id": "gpt-5-mini", "name": "gpt-5-mini"},
          {"id": "gpt-5-nano", "name": "gpt-5-nano"},
          {"id": "claude-opus-4.5", "name": "claude-opus-4.5"},
          {"id": "claude-sonnet-4.5", "name": "claude-sonnet-4.5"},
          {"id": "claude-haiku-4.5", "name": "claude-haiku-4.5"},
          {"id": "gemini-3-pro", "name": "gemini-3-pro"},
          {"id": "gemini-3-flash", "name": "gemini-3-flash"}
        ]'
        ;;
esac

echo ""
echo -e "${GREEN}✅ Models selected${NC}"
echo ""

# Step 4: Set default model
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 4: Set Default Model (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "Set AINFT as default model provider? [y/n]: " set_default

DEFAULT_MODEL=""
if [ "$set_default" = "y" ] || [ "$set_default" = "Y" ]; then
    echo ""
    if command -v python3 &> /dev/null; then
        ENABLED_MODELS=()
        while IFS= read -r line; do
            [ -n "$line" ] && ENABLED_MODELS+=("$line")
        done < <(
            python3 - "$MODELS" <<'PY'
import json
import sys
for m in json.loads(sys.argv[1]):
    mid = m.get("id")
    if mid:
        print(f"ainft/{mid}")
PY
        )

        echo "Select default model from enabled models:"
        for i in "${!ENABLED_MODELS[@]}"; do
            idx=$((i + 1))
            echo "$idx) ${ENABLED_MODELS[$i]}"
        done
        custom_idx=$((${#ENABLED_MODELS[@]} + 1))
        echo "$custom_idx) Custom model ID"
        echo ""
        read -p "Select default model [1-$custom_idx]: " default_choice

        if [[ "$default_choice" =~ ^[0-9]+$ ]] && [ "$default_choice" -ge 1 ] && [ "$default_choice" -le "${#ENABLED_MODELS[@]}" ]; then
            DEFAULT_MODEL="${ENABLED_MODELS[$((default_choice - 1))]}"
        elif [ "$default_choice" = "$custom_idx" ]; then
            read -p "Enter custom model ID (e.g., ainft/gpt-5.2): " custom_model
            DEFAULT_MODEL="$custom_model"
        else
            DEFAULT_MODEL="${ENABLED_MODELS[0]}"
        fi
    else
        # Fallback when python3 is unavailable.
        echo "Recommended models:"
        echo "1) ainft/gpt-5-nano (Fast & cheap)"
        echo "2) ainft/gpt-5-mini (Balanced)"
        echo "3) ainft/claude-sonnet-4.5 (Balanced Claude)"
        echo "4) Custom model ID"
        echo ""
        read -p "Select default model [1-4]: " default_choice
        
        case $default_choice in
            1) DEFAULT_MODEL="ainft/gpt-5-nano" ;;
            2) DEFAULT_MODEL="ainft/gpt-5-mini" ;;
            3) DEFAULT_MODEL="ainft/claude-sonnet-4.5" ;;
            4) 
                read -p "Enter custom model ID (e.g., ainft/gpt-5.2): " custom_model
                DEFAULT_MODEL="$custom_model"
                ;;
            *) DEFAULT_MODEL="ainft/gpt-5-nano" ;;
        esac
    fi
    
    echo ""
    echo -e "${GREEN}✅ Default model: $DEFAULT_MODEL${NC}"
fi

echo ""

# Step 5: Backup and update configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 5: Update Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Backup existing config
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"

# Create Python script to update JSON
PYTHON_SCRIPT=$(cat <<'PYTHON_EOF'
import json
import sys

config_file = sys.argv[1]
base_url = sys.argv[2]
api_key = sys.argv[3]
models_json = sys.argv[4]
default_model = sys.argv[5] if len(sys.argv) > 5 else ""

# Read existing config
with open(config_file, 'r') as f:
    config = json.load(f)

# Ensure models structure exists
if 'models' not in config:
    config['models'] = {}

if 'providers' not in config['models']:
    config['models']['providers'] = {}

# Set merge mode
config['models']['mode'] = 'merge'

# Add AINFT provider
config['models']['providers']['ainft'] = {
    'baseUrl': base_url,
    'apiKey': api_key,
    'api': 'openai-completions',
    'models': json.loads(models_json)
}

# Set default model if specified
if default_model:
    if 'agents' not in config:
        config['agents'] = {}
    if 'defaults' not in config['agents']:
        config['agents']['defaults'] = {}
    if 'model' not in config['agents']['defaults']:
        config['agents']['defaults']['model'] = {}
    
    config['agents']['defaults']['model']['primary'] = default_model

# Write updated config
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print("Configuration updated successfully!")
PYTHON_EOF
)

# Run Python script
if command -v python3 &> /dev/null; then
    echo "$PYTHON_SCRIPT" | python3 - "$CONFIG_FILE" "$BASE_URL" "$API_KEY" "$MODELS" "$DEFAULT_MODEL"
    echo -e "${GREEN}✅ Configuration updated${NC}"
else
    echo -e "${RED}❌ Python 3 not found. Manual configuration required.${NC}"
    echo ""
    echo "Please add this to your $CONFIG_FILE:"
    echo ""
    cat <<EOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "ainft": {
        "baseUrl": "$BASE_URL",
        "apiKey": "$API_KEY",
        "api": "openai-completions",
        "models": $MODELS
      }
    }
  }
}
EOF
    if [ -n "$DEFAULT_MODEL" ]; then
        echo ""
        echo "And set default model:"
        echo ""
        cat <<EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "$DEFAULT_MODEL"
      }
    }
  }
}
EOF
    fi
    exit 1
fi

echo ""

# Step 6: Restart OpenClaw
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 6: Restart OpenClaw${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v openclaw &> /dev/null; then
    echo "Restarting OpenClaw gateway..."
    openclaw gateway restart
    echo -e "${GREEN}✅ OpenClaw restarted${NC}"
else
    echo -e "${YELLOW}⚠️  OpenClaw command not found in PATH${NC}"
    echo "Please manually restart OpenClaw gateway:"
    echo "  openclaw gateway restart"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ AINFT Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Base URL: $BASE_URL"
echo "  Deposit Address: $DEPOSIT_ADDRESS"
if [ -n "$DEFAULT_MODEL" ]; then
    echo "  Default Model: $DEFAULT_MODEL"
fi
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Ensure you have deposited tokens to: $DEPOSIT_ADDRESS"
echo "2. Test your setup:"
if [ -n "$DEFAULT_MODEL" ]; then
    echo "     openclaw chat"
else
    echo "     openclaw chat --model ainft/gpt-5-nano"
fi
echo ""
echo -e "${BLUE}📚 Resources:${NC}"
echo "  AINFT Web: $WEB_URL"
echo "  API Key Management: ${WEB_URL}/key"
echo "  Documentation: https://github.com/RudolphHuang/openclaw_doc"
echo ""
echo -e "${GREEN}Happy chatting! 🚀${NC}"
echo ""
