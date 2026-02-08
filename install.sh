#!/bin/bash
set -euo pipefail

# OpenClaw Extension Installer (by BankofAI)

# --- Colors & Styling ---
BOLD='\033[1m'
ACCENT='\033[38;2;255;90;45m'      # Brand Orange
ACCENT_DIM='\033[38;2;209;74;34m'  # Darker Orange
INFO='\033[38;2;0;145;255m'        # Balanced Blue (Works on both light/dark)
SUCCESS='\033[38;2;0;200;83m'      # Balanced Green
WARN='\033[38;2;255;171;0m'        # Balanced Amber
ERROR='\033[38;2;211;47;47m'       # Balanced Red
MUTED='\033[38;2;128;128;128m'     # Medium Gray
NC='\033[0m' # No Color

# --- Configuration ---
# Ensure we have a TTY for user interaction, even if piped
if [ -t 0 ]; then
    exec 3<&0
elif [ -e /dev/tty ]; then
    exec 3</dev/tty
else
    # Fallback to stdin if no TTY, though interaction may fail
    exec 3<&0
fi

MCP_CONFIG_DIR="$HOME/.mcporter"
MCP_CONFIG_FILE="$MCP_CONFIG_DIR/mcporter.json"
TMPFILES=()

# --- Cleanup Trap ---
cleanup() {
    local f
    for f in "${TMPFILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
    # Restore cursor
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

# --- Helper Functions ---

mktempfile() {
    local f
    f="$(mktemp)"
    TMPFILES+=("$f")
    echo "$f"
}

# --- Taglines ---
TAGLINES=(
    "TRON agents: Low fees, high speeds, zero excuses."
    "Managing your wallet faster than SunPump drops a new meme."
    "Private keys stay private. We're a bank, not a billboard."
    "Energy rental? Bandwidth? I'll calculate it so you don't have to."
    "Your financial sovereignty, now with automated claws."
    "TRC-20 automation: Sending tokens like it's text messages."
    "Smart contracts, smarter agent. No more manual ABI guessing."
    "OpenClaw Extension: Where AI meets DeFi, and your portfolio thanks you."
)

pick_tagline() {
    local count=${#TAGLINES[@]}
    local idx=$((RANDOM % count))
    echo "${TAGLINES[$idx]}"
}

TAGLINE=$(pick_tagline)

# --- Pre-flight Checks ---

check_env() {
    if ! command -v node &> /dev/null; then
        echo -e "${ERROR}Error: Node.js is not installed.${NC}"
        exit 1
    fi
    if ! command -v npx &> /dev/null; then
        echo -e "${ERROR}Error: 'npx' is not found.${NC}"
        exit 1
    fi

    # Detect Python interpreter
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        echo -e "${ERROR}Error: Neither 'python3' nor 'python' found (required for JSON processing).${NC}"
        exit 1
    fi
}

# --- JSON Helper (Generic) ---
# Usage: write_server_config "server_name" "json_payload_string" "config_file"
write_server_config() {
    local server="$1"
    local json_payload="$2"
    local config_file="$3"

    local py_scrip
    py_script=$(mktempfile)

    local payload_file
    payload_file=$(mktempfile)
    echo "$json_payload" > "$payload_file"

    cat <<EOF > "$py_script"
import json
import os
import sys

file_path = '$config_file'
server_name = '$server'
payload_file = '$payload_file'

try:
    with open(payload_file, 'r') as f:
        payload = json.load(f)
except Exception:
    sys.exit(1)

data = {}
if os.path.exists(file_path):
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            if content.strip():
                data = json.loads(content)
    except ValueError:
        pass

if 'mcpServers' not in data:
    data['mcpServers'] = {}

if server_name not in data['mcpServers']:
    data['mcpServers'][server_name] = {}

# Deep merge logic for 'env' to avoid overwriting existing keys if not specified
if 'env' in payload:
    if 'env' not in data['mcpServers'][server_name]:
        data['mcpServers'][server_name]['env'] = {}

    for k, v in payload['env'].items():
        if v is None or v == "":
             # Remove key if it exists
             if k in data['mcpServers'][server_name]['env']:
                 del data['mcpServers'][server_name]['env'][k]
        else:
             data['mcpServers'][server_name]['env'][k] = v

    # Remove 'env' from payload so we don't overwrite the dict we just updated
    del payload['env']

# Update other top-level keys (command, args, etc.)
for k, v in payload.items():
    data['mcpServers'][server_name][k] = v

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2)
EOF
    $PYTHON_CMD "$py_script"
}

ask_input() {
    local prompt="$1"
    local var_name="$2"
    local is_secret="${3:-0}"
    local description="${4:-}"
    local input_val

    if [[ -n "$description" ]]; then
        echo -e "${MUTED}  $description${NC}"
    fi

    # Prompt text styling updated
    echo -ne "${INFO}?${NC} $prompt ${MUTED}(optional)${NC}: "

    if [[ "$is_secret" == "1" ]]; then
        read -rs input_val <&3
        echo ""
    else
        read -r input_val <&3
    fi
    printf -v "$var_name" '%s' "$input_val"
}

# --- Multiselect Function (Fixed Logic) ---
multiselect() {
    local prompt="$1"
    local result_var="$2"
    shift 2
    local options=("$@")
    local selected=()
    local current=0
    local i

    # Initialize selection
    for ((i=0; i<${#options[@]}; i++)); do selected[i]=true; done # Default all to true

    # Prepare screen area
    echo -e "${INFO}?${NC} ${BOLD}$prompt${NC} ${MUTED}(Space:toggle, Enter:confirm)${NC}"
    for ((i=0; i<${#options[@]}; i++)); do echo ""; done

    tput civis # Hide cursor

    while true; do
        # Move cursor up to start of lis
        tput cuu ${#options[@]}

        for ((i=0; i<${#options[@]}; i++)); do
            tput el # Clear line

            local checkbox="[ ]"
            local color="$NC"
            local pointer="  "

            if [ "${selected[i]}" = true ]; then
                checkbox="${SUCCESS}[x]${NC}"
                color="$BOLD"
            fi

            if [ $i -eq $current ]; then
                pointer="${ACCENT}❯ ${NC}"
                color="${ACCENT}"
                if [ "${selected[i]}" = true ]; then
                    checkbox="${ACCENT}[x]${NC}"
                else
                    checkbox="${ACCENT}[ ]${NC}"
                fi
            fi

            echo -e "${pointer}${checkbox} ${color}${options[i]}${NC}"
        done

        # Read Input (with IFS cleared to capture space correctly)
        local key=""
        IFS= read -rsn1 key <&3

        case "$key" in
            "") # Enter key (empty string)
                break
                ;;
            " ") # Space key
                if [ "${selected[$current]}" = true ]; then
                    selected[$current]=false
                else
                    selected[$current]=true
                fi
                ;;
            $'\x1b') # Escape sequence
                read -rsn2 -t 0.1 key <&3
                case "$key" in
                    "[A") # Up Arrow
                        ((current--)) || true
                        if [ $current -lt 0 ]; then current=$((${#options[@]} - 1)); fi
                        ;;
                    "[B") # Down Arrow
                        ((current++)) || true
                        if [ $current -ge ${#options[@]} ]; then current=0; fi
                        ;;
                esac
                ;;
        esac
    done

    tput cnorm # Show cursor

    # Return results
    local indices=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [ "${selected[i]}" = true ]; then indices+=("$i"); fi
    done
    eval $result_var="(${indices[@]})"
}

# --- Main Logic ---

echo -e "${ACCENT}${BOLD}"
echo "  🦞 OpenClaw Extension Installer (by BankofAI)"
echo -e "${NC}${ACCENT_DIM}  $TAGLINE${NC}"
echo ""

check_env

# Ensure config directory exists
mkdir -p "$MCP_CONFIG_DIR"

# --- Step 1: Skills (Multiselect) ---

# Define Skill Options
SKILL_OPTIONS=("mcporter - MCP server manager and configuration tool" "x402-tron-payment - Enables agent payments on TRON network (x402 protocol)" "x402-tron-payment-demo - Demo of x402 payment protocol by fetching a protected image.")
SKILL_IDS=("mcporter" "x402-tron-payment" "x402-tron-payment-demo")

if [ ${#SKILL_OPTIONS[@]} -gt 0 ]; then
    echo ""
    SELECTED_SKILL_INDICES=()
    multiselect "Select Skills/Tools to install:" SELECTED_SKILL_INDICES "${SKILL_OPTIONS[@]}"

    if [ ${#SELECTED_SKILL_INDICES[@]} -gt 0 ]; then
        for idx in "${SELECTED_SKILL_INDICES[@]}"; do
            SKILL_ID="${SKILL_IDS[$idx]}"
            echo -e "${INFO}Installing: $SKILL_ID...${NC}"
            npx clawhub install --force "$SKILL_ID"
        done
    else
        echo -e "${MUTED}No skills selected.${NC}"
    fi
else
    echo ""
    echo -e "${BOLD}Install Skills:${NC}"
    echo -e "${MUTED}(No additional skills currently available)${NC}"
fi

# --- Step 2: Server Selection (Multiselect) ---

# Define Server Options and mapping
SERVER_OPTIONS=("mcp-server-tron - Interact with TRON blockchain (Wallets, Transactions, Smart Contracts)")
SERVER_IDS=("mcp-server-tron")

SELECTED_INDICES=()
multiselect "Select MCP Servers to install:" SELECTED_INDICES "${SERVER_OPTIONS[@]}"

if [ ${#SELECTED_INDICES[@]} -eq 0 ]; then
    echo -e "${WARN}No servers selected. Exiting.${NC}"
    exit 0
fi

# --- Step 3: Configuration ---

for idx in "${SELECTED_INDICES[@]}"; do
    SERVER_ID="${SERVER_IDS[$idx]}"

    echo ""
    echo -e "${BOLD}Configuring $SERVER_ID...${NC}"

    case "$SERVER_ID" in
        "mcp-server-tron")
             echo -e "${WARN}!!! SECURITY WARNING !!!${NC}"
             echo -e "${WARN}Sensitive keys will be saved in PLAINTEXT to: ${INFO}$MCP_CONFIG_FILE${NC}"
             echo -e "${WARN}DO NOT allow AI agents to scan this file.${NC}"
             echo ""

             ask_input "Enter TRON_PRIVATE_KEY" TRON_KEY 0 "Your TRON wallet private key. Required for signing transactions."
             ask_input "Enter TRONGRID_API_KEY" TRON_API_KEY 0 "Your TronGrid API Key. Required for reliable network access."

             echo -e "${MUTED}Saving configuration...${NC}"

             # Construct JSON payload for this server
             # Env vars + Command + Args

             # We construct env part manually for simplicity in bash, treating empty values as nulls
             # Python helper handles None/null by removing the key

             TRON_KEY_VAL="\"$TRON_KEY\""
             if [ -z "$TRON_KEY" ]; then TRON_KEY_VAL="null"; fi

             TRON_API_KEY_VAL="\"$TRON_API_KEY\""
             if [ -z "$TRON_API_KEY" ]; then TRON_API_KEY_VAL="null"; fi

             JSON_PAYLOAD=$(cat <<EOF
{
  "command": "npx",
  "args": ["-y", "@bankofai/mcp-server-tron"],
  "env": {
    "TRON_PRIVATE_KEY": $TRON_KEY_VAL,
    "TRONGRID_API_KEY": $TRON_API_KEY_VAL
  }
}
EOF
)
             write_server_config "$SERVER_ID" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"
             ;;
    esac

    echo -e "${SUCCESS}✓ Configuration saved for $SERVER_ID.${NC}"
done

# --- Final Summary ---
echo ""
echo -e "${ACCENT}${BOLD}Installation Complete!${NC}"
echo -e "${SUCCESS}✓${NC} Configuration file: ${INFO}$MCP_CONFIG_FILE${NC}"
echo -e "${WARN}→${NC} Please secure your config file:"
echo -e "   ${BOLD}chmod 600 $MCP_CONFIG_FILE${NC}"
echo ""
