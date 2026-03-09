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
AINFT_CONFIG_DIR="$HOME/.ainft"
AINFT_CONFIG_FILE="$AINFT_CONFIG_DIR/config.json"
TMP_AINFT_MODEL_FILE="$(mktemp)"
trap 'rm -f "$TMP_AINFT_MODEL_FILE"' EXIT

require_python3() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 is required but not found in PATH.${NC}"
        exit 1
    fi
}

check_node_version() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed or not in PATH.${NC}"
        exit 1
    fi

    local node_version major_version
    node_version="$(node -v 2>/dev/null || true)"
    major_version="$(echo "$node_version" | sed -E 's/^v([0-9]+).*/\1/')"
    if [ -z "$major_version" ] || [ "$major_version" -lt 22 ]; then
        echo -e "${RED}❌ Node.js >= 22 is required. Current version: ${node_version:-unknown}${NC}"
        exit 1
    fi
}

# Check if OpenClaw is installed
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: OpenClaw configuration not found at $CONFIG_FILE${NC}"
    echo -e "${YELLOW}Please install OpenClaw first: https://github.com/openclaw${NC}"
    exit 1
fi

require_python3
check_node_version

echo -e "${GREEN}✅ Found OpenClaw configuration${NC}"
echo ""

# Step 1: Production configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1: Production Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ENVIRONMENT="prod"
BASE_URL="https://chat.ainft.com/webapi/"
WEB_URL="https://chat.ainft.com"

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
echo "3. API key input below is hidden (no echo)"
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

# Step 2.5: Validate API key and fetch models
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2.5: Validate API Key & Fetch Models${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
python3 - "$WEB_URL" "$API_KEY" "$TMP_AINFT_MODEL_FILE" <<'PY'
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

web_url = sys.argv[1].rstrip("/")
api_key = sys.argv[2].strip()
output_file = sys.argv[3]

def post_raw(url: str, payload: dict, headers: dict | None = None):
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers or {}, method="POST")
    with urllib.request.urlopen(req, timeout=20) as resp:
        return resp.status, dict(resp.headers), resp.read().decode("utf-8", errors="replace")

def get_json(url: str):
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode("utf-8"))

def normalize_name(model_id: str) -> str:
    mapping = {
        "claude-opus-4-6": "claude-opus-4.6",
        "claude-opus-4-5-20251101": "claude-opus-4.5",
        "claude-sonnet-4-6": "claude-sonnet-4.6",
        "claude-sonnet-4-5-20250929": "claude-sonnet-4.5",
        "claude-haiku-4-5-20251001": "claude-haiku-4.5",
        "gemini-3.1-pro-preview": "gemini-3.1-pro",
        "gemini-3-flash-preview": "gemini-3-flash",
    }
    return mapping.get(model_id, model_id)

chat_url = f"{web_url}/webapi/chat/completions"
validate_payload = {
    "model": "gpt-5-nano",
    "messages": [{"role": "user", "content": "Reply with exactly OK."}],
    "max_tokens": 8,
}
headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json",
}

try:
    status, resp_headers, resp_body = post_raw(chat_url, validate_payload, headers=headers)
    content_type = (resp_headers.get("Content-Type") or "").lower()
    stripped = resp_body.lstrip()
    if status != 200:
        print(f"ERROR: API key validation returned unexpected HTTP {status}.", file=sys.stderr)
        raise SystemExit(1)
    if stripped.startswith("data:") or "text/event-stream" in content_type:
        pass
    elif stripped.startswith("{"):
        json.loads(stripped)
    elif not stripped:
        print("ERROR: API key validation returned an empty response body.", file=sys.stderr)
        raise SystemExit(1)
    else:
        print("ERROR: API key validation returned an unexpected response format.", file=sys.stderr)
        print(stripped[:400], file=sys.stderr)
        raise SystemExit(1)
except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8", errors="replace")
    if exc.code == 401:
        print("ERROR: AINFT API key is invalid or unauthorized.", file=sys.stderr)
    else:
        print(f"ERROR: API key validation failed with HTTP {exc.code}.", file=sys.stderr)
    if body:
        print(body[:400], file=sys.stderr)
    raise SystemExit(1)
except Exception as exc:
    print(f"ERROR: API key validation failed: {exc}", file=sys.stderr)
    raise SystemExit(1)

trpc_input = urllib.parse.quote(
    json.dumps({"0": {"json": None, "meta": {"values": ["undefined"], "v": 1}}}, separators=(",", ":"))
)
config_url = f"{web_url}/trpc/lambda/config.getGlobalConfig?batch=1&input={trpc_input}"

try:
    config_resp = get_json(config_url)
except Exception as exc:
    print(f"ERROR: Failed to fetch dynamic model list: {exc}", file=sys.stderr)
    raise SystemExit(1)

config_json = ((config_resp or [{}])[0].get("result") or {}).get("data", {}).get("json", {})
providers = (config_json.get("serverConfig") or {}).get("aiProvider") or {}

groups = []
for provider_key, title in (("openai", "OpenAI"), ("anthropic", "Claude"), ("google", "Gemini")):
    entries = []
    for item in (providers.get(provider_key) or {}).get("serverModelLists", []) or []:
        model_id = item.get("modelId") or item.get("id") or item.get("name")
        if not model_id:
            continue
        entries.append({"id": model_id, "name": normalize_name(model_id)})
    if entries:
        groups.append({"key": provider_key, "title": title, "models": entries})

all_models = []
seen = set()
for group in groups:
    for model in group["models"]:
        if model["id"] in seen:
            continue
        seen.add(model["id"])
        all_models.append(model)

if not all_models:
    print("ERROR: No AINFT models were returned by config.getGlobalConfig.", file=sys.stderr)
    raise SystemExit(1)

with open(output_file, "w", encoding="utf-8") as f:
    json.dump({"groups": groups, "all": all_models}, f, ensure_ascii=False, indent=2)
PY

echo -e "${GREEN}✅ API key validation passed${NC}"
echo -e "${GREEN}✅ Dynamic model list fetched${NC}"
echo ""

# Step 2.6: Write local AINFT skill config
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2.6: Write AINFT Skill Config${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
mkdir -p "$AINFT_CONFIG_DIR"
if [ -f "$AINFT_CONFIG_FILE" ]; then
    AINFT_BACKUP="${AINFT_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$AINFT_CONFIG_FILE" "$AINFT_BACKUP"
    echo -e "${GREEN}✅ Existing AINFT config backed up: $AINFT_BACKUP${NC}"
fi
cat > "$AINFT_CONFIG_FILE" <<EOF
{
  "api_key": "$API_KEY",
  "base_url": "$WEB_URL",
  "timeout_ms": 15000
}
EOF
chmod 600 "$AINFT_CONFIG_FILE"
echo -e "${GREEN}✅ AINFT skill config written: $AINFT_CONFIG_FILE${NC}"
echo ""

# Step 3: Select models
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Select Models${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1) All available models"
echo "2) OpenAI family only"
echo "3) Claude family only"
echo "4) Gemini family only"
echo ""
read -p "Select models [1-4]: " model_choice

case $model_choice in
    1)
        MODELS="$(python3 - "$TMP_AINFT_MODEL_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(json.dumps(data.get('all', []), ensure_ascii=False))
PY
)"
        ;;
    2)
        MODELS="$(python3 - "$TMP_AINFT_MODEL_FILE" openai <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
group = next((g for g in data.get('groups', []) if g.get('key') == sys.argv[2]), {})
print(json.dumps(group.get('models', []), ensure_ascii=False))
PY
)"
        ;;
    3)
        MODELS="$(python3 - "$TMP_AINFT_MODEL_FILE" anthropic <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
group = next((g for g in data.get('groups', []) if g.get('key') == sys.argv[2]), {})
print(json.dumps(group.get('models', []), ensure_ascii=False))
PY
)"
        ;;
    4)
        MODELS="$(python3 - "$TMP_AINFT_MODEL_FILE" google <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
group = next((g for g in data.get('groups', []) if g.get('key') == sys.argv[2]), {})
print(json.dumps(group.get('models', []), ensure_ascii=False))
PY
)"
        ;;
    *)
        echo -e "${RED}Invalid choice. Using all models.${NC}"
        MODELS="$(python3 - "$TMP_AINFT_MODEL_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(json.dumps(data.get('all', []), ensure_ascii=False))
PY
)"
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
        MODEL_LIST_OUTPUT="$(
            python3 - "$MODELS" <<'PY'
import json
import sys
for m in json.loads(sys.argv[1]):
    mid = m.get("id")
    if mid:
        print(f"ainft/{mid}")
PY
        )"
        while IFS= read -r line; do
            [ -n "$line" ] && ENABLED_MODELS+=("$line")
        done <<EOF
$MODEL_LIST_OUTPUT
EOF

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
        echo "1) ainft/gpt-5-nano (Recommended)"
        echo "2) ainft/gpt-5-mini"
        echo "3) ainft/claude-sonnet-4-6"
        echo "4) Custom model ID"
        echo ""
        read -p "Select default model [1-4]: " default_choice
        
        case $default_choice in
            1) DEFAULT_MODEL="ainft/gpt-5-nano" ;;
            2) DEFAULT_MODEL="ainft/gpt-5-mini" ;;
            3) DEFAULT_MODEL="ainft/claude-sonnet-4-6" ;;
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
provider_models = json.loads(models_json)
config['models']['providers']['ainft'] = {
    'baseUrl': base_url,
    'apiKey': api_key,
    'api': 'openai-completions',
    'models': provider_models
}

# Ensure enabled AINFT models are in agents.defaults.models allowlist (if used).
if 'agents' not in config:
    config['agents'] = {}
if 'default' in config['agents']:
    del config['agents']['default']
if 'defaults' not in config['agents']:
    config['agents']['defaults'] = {}

allowlist = config['agents']['defaults'].get('models')
if not isinstance(allowlist, dict):
    allowlist = {}

for key in list(allowlist.keys()):
    if isinstance(key, str) and key.startswith('ainft/'):
        del allowlist[key]

for m in provider_models:
    mid = m.get('id')
    if mid:
        allowlist.setdefault(f'ainft/{mid}', {})

config['agents']['defaults']['models'] = allowlist

# Set default model if specified
if default_model:
    if 'defaults' not in config['agents'] or not isinstance(config['agents']['defaults'], dict):
        config['agents']['defaults'] = {}
    model_cfg = config['agents']['defaults'].get('model')
    if not isinstance(model_cfg, dict):
        model_cfg = {}
    model_cfg['primary'] = default_model
    config['agents']['defaults']['model'] = model_cfg

    # If the main agent is already materialized, keep it aligned with the new
    # default model. Otherwise the explicit per-agent override will continue to
    # win over agents.defaults.model.primary.
    agent_list = config['agents'].get('list')
    if isinstance(agent_list, list):
        for agent in agent_list:
            if isinstance(agent, dict) and agent.get('id') == 'main':
                agent['model'] = default_model
                break

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
    if [ -n "$DEFAULT_MODEL" ]; then
        echo "Setting OpenClaw default model to $DEFAULT_MODEL..."
        if openclaw models set "$DEFAULT_MODEL" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ OpenClaw default model updated${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to apply default model via CLI. The config file was updated directly.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  OpenClaw command not found in PATH${NC}"
    echo "Please manually restart OpenClaw gateway:"
    echo "  openclaw gateway restart"
    if [ -n "$DEFAULT_MODEL" ]; then
        echo "If your config already has agents.list.main.model, make sure it matches too."
        echo "This script already updates both agents.defaults.model.primary and agents.list.main.model."
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ AINFT Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Base URL: $BASE_URL"
echo "  AINFT Skill Config: $AINFT_CONFIG_FILE"
if [ -n "$DEFAULT_MODEL" ]; then
    echo "  Default Model: $DEFAULT_MODEL"
fi
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Test your setup:"
if [ -n "$DEFAULT_MODEL" ]; then
    echo "     openclaw agent --agent main --message \"你好\""
else
    echo "     openclaw models set ainft/gpt-5-nano"
    echo "     openclaw agent --agent main --message \"你好\""
fi
echo ""
echo -e "${BLUE}📚 Resources:${NC}"
echo "  AINFT Web: $WEB_URL"
echo "  API Key Management: ${WEB_URL}/key"
echo "  Documentation: https://docs.apenft.io/docs/openclaw%E6%8E%A5%E5%85%A5ainft%E6%93%8D%E4%BD%9C%E6%8C%87%E5%8D%97"
echo ""
echo -e "${GREEN}Happy chatting! 🚀${NC}"
echo ""
