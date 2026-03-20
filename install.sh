#!/bin/bash
set -euo pipefail

# OpenClaw Extension Installer (by BANK OF AI)
# Installs MCP server and TRON skills from GitHub

# --- Colors & Styling ---
BOLD='\033[1m'
ACCENT='\033[38;2;255;90;45m'
ACCENT_DIM='\033[38;2;209;74;34m'
INFO='\033[38;2;0;145;255m'
SUCCESS='\033[38;2;0;200;83m'
WARN='\033[38;2;255;171;0m'
ERROR='\033[38;2;211;47;47m'
MUTED='\033[38;2;128;128;128m'
NC='\033[0m'

# --- Configuration ---
if [ -t 0 ]; then
    exec 3<&0
elif [ -e /dev/tty ]; then
    exec 3</dev/tty
else
    exec 3<&0
fi

MCP_CONFIG_DIR="$HOME/.mcporter"
MCP_CONFIG_FILE="$MCP_CONFIG_DIR/mcporter.json"
OPENCLAW_USER_SKILLS="$HOME/.openclaw/skills"
OPENCLAW_WORKSPACE_SKILLS=".openclaw/skills"
GITHUB_REPO="https://github.com/BofAI/skills.git"
GITHUB_BRANCH="${GITHUB_BRANCH:-v1.5.0.beta.1}"
AGENT_WALLET_VERSION="2.3.0-beta.6"
TMPFILES=()
TEMP_DIR=""
INSTALLED_SKILLS=()
CLEAN_INSTALL=false

# --- Cleanup ---
cleanup() {
    local f
    for f in "${TMPFILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
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
    if ! command -v git &> /dev/null; then
        echo -e "${ERROR}Error: git is not installed.${NC}"
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
    
    # Check if OpenClaw is installed (mcporter config directory should exist)
    if [ ! -d "$HOME/.openclaw" ]; then
        echo -e "${WARN}Warning: OpenClaw doesn't appear to be installed.${NC}"
        echo -e "${WARN}This installer requires OpenClaw to be installed first.${NC}"
        echo -e "${INFO}Install OpenClaw from: https://github.com/openclaw${NC}"
        echo ""
        echo -ne "${INFO}?${NC} Continue anyway? ${MUTED}(y/N)${NC}: "
        read -r continue_choice <&3
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# --- JSON Helper ---
write_server_config() {
    local server="$1"
    local json_payload="$2"
    local config_file="$3"

    local py_script
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

# Deep merge logic for 'env'
if 'env' in payload:
    if 'env' not in data['mcpServers'][server_name]:
        data['mcpServers'][server_name]['env'] = {}

    for k, v in payload['env'].items():
        if v is None or v == "":
             if k in data['mcpServers'][server_name]['env']:
                 del data['mcpServers'][server_name]['env'][k]
        else:
             data['mcpServers'][server_name]['env'][k] = v

    del payload['env']

# Update other top-level keys
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

    echo -ne "${INFO}?${NC} $prompt ${MUTED}(optional)${NC}: "

    if [[ "$is_secret" == "1" ]]; then
        read -rs input_val <&3
        echo ""
    else
        read -r input_val <&3
    fi
    printf -v "$var_name" '%s' "$input_val"
}

json_string_or_null() {
    local value="${1:-}"
    if [ -z "$value" ]; then
        echo "null"
    else
        printf '%s' "$value" | $PYTHON_CMD -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
    fi
}

clear_all_mcp_entries() {
    mkdir -p "$MCP_CONFIG_DIR"
    MCP_FILE_PATH="$MCP_CONFIG_FILE" $PYTHON_CMD - <<'PY'
import json
import os

path = os.environ["MCP_FILE_PATH"]
data = {}

if os.path.exists(path):
    try:
        with open(path, "r") as f:
            content = f.read().strip()
            if content:
                data = json.loads(content)
    except Exception:
        data = {}

data["mcpServers"] = {}

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
}

clear_all_skills_under_dir() {
    local skills_dir="$1"
    if [ -d "$skills_dir" ]; then
        find "$skills_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    fi
}

run_clean_install() {
    echo ""
    echo -e "${ERROR}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo -e "${ERROR}${BOLD}!!!                    CLEAN INSTALL MODE                    !!!${NC}"
    echo -e "${ERROR}${BOLD}!!!                  THIS ACTION IS IRREVERSIBLE             !!!${NC}"
    echo -e "${ERROR}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo ""
    echo -e "${WARN}The following data will be permanently deleted:${NC}"
    echo -e "  ${WARN}•${NC} ALL MCP entries in: ${INFO}$MCP_CONFIG_FILE${NC}"
    echo -e "  ${WARN}•${NC} ALL skills in: ${INFO}$OPENCLAW_USER_SKILLS${NC} and ${INFO}$OPENCLAW_WORKSPACE_SKILLS${NC}"
    echo -e "  ${WARN}•${NC} x402 config file: ${INFO}$HOME/.x402-config.json${NC}"
    echo -e "  ${WARN}•${NC} BANK OF AI local config: ${INFO}$HOME/.mcporter/bankofai-config.json${NC}"
    echo -e "  ${WARN}•${NC} AgentWallet config will be overwritten by: ${INFO}agent-wallet start --override${NC}"
    echo ""
    echo -ne "${ERROR}?${NC} Continue with CLEAN install? ${MUTED}(y/N)${NC}: "
    read -r clean_confirm <&3
    if [[ ! "$clean_confirm" =~ ^[Yy]$ ]]; then
        echo -e "${MUTED}Clean install cancelled.${NC}"
        echo ""
        return 0
    fi

    echo -ne "${ERROR}?${NC} Type ${BOLD}CLEAN${NC}${ERROR} to confirm permanent deletion${NC}: "
    read -r clean_word <&3
    if [ "$clean_word" != "CLEAN" ]; then
        echo -e "${WARN}Confirmation text mismatch. Clean install cancelled.${NC}"
        echo ""
        return 0
    fi

    echo ""
    echo -e "${INFO}Running cleanup...${NC}"
    clear_all_mcp_entries
    clear_all_skills_under_dir "$OPENCLAW_USER_SKILLS"
    clear_all_skills_under_dir "$OPENCLAW_WORKSPACE_SKILLS"
    rm -f "$HOME/.x402-config.json"
    rm -f "$HOME/.mcporter/bankofai-config.json"
    echo -e "${SUCCESS}✓ Clean install cleanup completed.${NC}"
    echo ""
}

choose_install_mode() {
    echo ""
    echo -e "${BOLD}Installation Mode${NC}"
    echo -e "  ${INFO}1)${NC} Normal install ${SUCCESS}[Recommended]${NC}"
    echo -e "  ${INFO}2)${NC} Clean install ${WARN}(full cleanup: MCP/skills/local config files)${NC}"
    echo ""
    echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-2, default: 1)${NC}: "
    read -r install_mode_choice <&3
    install_mode_choice=${install_mode_choice:-1}

    if [ "$install_mode_choice" = "2" ]; then
        CLEAN_INSTALL=true
        run_clean_install
    fi
}

ensure_agent_wallet_cli() {
    local current_version=""
    local npm_list_output=""

    if npm_list_output=$(npm list -g --depth=0 @bankofai/agent-wallet 2>/dev/null); then
        current_version=$(printf '%s\n' "$npm_list_output" | sed -n 's/.*@bankofai\/agent-wallet@\([^[:space:]]*\).*/\1/p' | head -n 1)
    fi

    if [ "$current_version" = "$AGENT_WALLET_VERSION" ]; then
        return 0
    fi

    if [ -n "$current_version" ]; then
        echo -e "${INFO}Updating AgentWallet CLI to ${AGENT_WALLET_VERSION}...${NC}"
    else
        echo -e "${INFO}Installing AgentWallet CLI ${AGENT_WALLET_VERSION}...${NC}"
    fi

    if ! npm install -g "@bankofai/agent-wallet@${AGENT_WALLET_VERSION}"; then
        echo -e "${ERROR}Error: Failed to install AgentWallet CLI ${AGENT_WALLET_VERSION}.${NC}"
        echo -e "${INFO}Try manually: npm install -g @bankofai/agent-wallet@${AGENT_WALLET_VERSION}${NC}"
        exit 1
    fi

    current_version=""
    if npm_list_output=$(npm list -g --depth=0 @bankofai/agent-wallet 2>/dev/null); then
        current_version=$(printf '%s\n' "$npm_list_output" | sed -n 's/.*@bankofai\/agent-wallet@\([^[:space:]]*\).*/\1/p' | head -n 1)
    fi
    if [ "$current_version" != "$AGENT_WALLET_VERSION" ]; then
        echo -e "${ERROR}Error: Expected AgentWallet ${AGENT_WALLET_VERSION}, but got '${current_version:-unknown}'.${NC}"
        exit 1
    fi
}

run_agent_wallet_cli() {
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        agent-wallet "$@" </dev/tty >/dev/tty 2>&1
    else
        agent-wallet "$@"
    fi
}

setup_agent_wallet() {
    echo ""
    echo -e "${BOLD}Step 0: AgentWallet Setup${NC}"
    echo ""

    ensure_agent_wallet_cli

    if [ "$CLEAN_INSTALL" = true ]; then
        echo -e "${INFO}Launching: agent-wallet reset${NC}"
        if ! run_agent_wallet_cli reset; then
            echo -e "${WARN}AgentWallet reset skipped or failed; continuing with clean initialization.${NC}"
        fi
        echo ""
        echo -e "${INFO}Launching: agent-wallet start --override${NC}"
        echo -e "${MUTED}Please complete initialization in the CLI prompts.${NC}"
        echo ""
        if ! run_agent_wallet_cli start --override; then
            echo -e "${ERROR}AgentWallet initialization failed in CLEAN mode.${NC}"
            exit 1
        fi
    else
        echo -e "${INFO}Launching: agent-wallet start${NC}"
        echo -e "${MUTED}Please complete initialization in the CLI prompts.${NC}"
        echo ""
        if ! run_agent_wallet_cli start; then
            echo -e "${ERROR}AgentWallet initialization failed.${NC}"
            exit 1
        fi
    fi

    echo ""
    echo -e "${SUCCESS}✓ AgentWallet setup completed${NC}"
    echo ""
}

# --- Multiselect Function ---
multiselect() {
    local prompt="$1"
    local result_var="$2"
    shift 2
    local options=("$@")
    local selected=()
    local current=0
    local i

    # Initialize selection - all selected by default
    for ((i=0; i<${#options[@]}; i++)); do
        selected[i]=true
    done

    # Prepare screen area
    echo -e "${INFO}?${NC} ${BOLD}$prompt${NC} ${MUTED}(Space:toggle, Enter:confirm)${NC}"
    for ((i=0; i<${#options[@]}; i++)); do
        echo ""
    done

    tput civis # Hide cursor

    while true; do
        # Move cursor up to start of list
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

        # Read Input
        local key=""
        IFS= read -rsn1 key <&3

        case "$key" in
            "")
                break
                ;;
            " ")
                if [ "${selected[$current]}" = true ]; then
                    selected[$current]=false
                else
                    selected[$current]=true
                fi
                ;;
            $'\x1b')
                read -rsn2 -t 0.1 key <&3
                case "$key" in
                    "[A")
                        ((current--)) || true
                        if [ $current -lt 0 ]; then
                            current=$((${#options[@]} - 1))
                        fi
                        ;;
                    "[B")
                        ((current++)) || true
                        if [ $current -ge ${#options[@]} ]; then
                            current=0
                        fi
                        ;;
                esac
                ;;
        esac
    done

    tput cnorm # Show cursor

    # Return results
    local indices=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [ "${selected[i]}" = true ]; then
            indices+=("$i")
        fi
    done
    eval $result_var="(${indices[@]})"
}

# --- Skills Installation Functions ---

clone_skills_repo() {
    echo -e "${INFO}Cloning skills repository ($GITHUB_BRANCH)...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    if ! git clone --depth 1 -b "$GITHUB_BRANCH" "$GITHUB_REPO" "$TEMP_DIR" 2>/dev/null; then
        echo -e "${ERROR}Error: Failed to clone repository from $GITHUB_REPO${NC}"
        return 1
    fi
    
    echo -e "${SUCCESS}✓ Repository cloned${NC}"
    echo ""
    return 0
}

select_install_target() {
    echo -e "${BOLD}Select skills installation location:${NC}"
    echo -e "  ${INFO}1)${NC} User-level (${INFO}~/.openclaw/skills/${NC}) ${SUCCESS}[Recommended]${NC}"
    echo -e "     ${MUTED}Available to all OpenClaw workspaces${NC}"
    echo -e "  ${INFO}2)${NC} Workspace-level (${INFO}.openclaw/skills/${NC})"
    echo -e "     ${MUTED}Only available in current workspace${NC}"
    echo -e "  ${INFO}3)${NC} Custom path"
    echo ""
    echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-3, default: 1)${NC}: "
    
    read -r choice <&3
    choice=${choice:-1}
    
    case $choice in
        1)
            TARGET_DIR="$OPENCLAW_USER_SKILLS"
            ;;
        2)
            TARGET_DIR="$OPENCLAW_WORKSPACE_SKILLS"
            ;;
        3)
            echo -ne "${INFO}?${NC} Enter custom path: "
            read -r TARGET_DIR <&3
            TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
            ;;
        *)
            echo -e "${WARN}Invalid choice, using default${NC}"
            TARGET_DIR="$OPENCLAW_USER_SKILLS"
            ;;
    esac
    
    echo -e "${MUTED}→ Installing to: ${INFO}$TARGET_DIR${NC}"
    echo ""
}

pretty_skill_name() {
    local skill_id="$1"
    case "$skill_id" in
        "recharge-skill") echo "recharge-skill" ;;
        *) echo "$skill_id" ;;
    esac
}

configure_bankofai_api_key() {
    echo ""
    echo -e "${BOLD}recharge-skill API Key Configuration${NC}"
    echo -e "${MUTED}recharge-skill uses your local BANK OF AI API key for balance and order queries.${NC}"
    echo -e "${MUTED}Recharge requests use the remote BANK OF AI recharge MCP endpoint.${NC}"
    echo ""

    local bankofai_config="$HOME/.mcporter/bankofai-config.json"
    local has_key="no"

    if [ -f "$bankofai_config" ]; then
        has_key=$($PYTHON_CMD -c "
import json
try:
    c = json.load(open('$bankofai_config'))
    print('yes' if c.get('api_key') else 'no')
except Exception:
    print('no')
" 2>/dev/null)
    fi

    if [ "$has_key" = "yes" ]; then
        echo -e "${SUCCESS}✓ BANK OF AI API key already configured${NC}"
        echo -e "${MUTED}  Config: $bankofai_config${NC}"
        echo ""
        echo -ne "${INFO}?${NC} Reconfigure BANK OF AI API key? ${MUTED}(y/N)${NC}: "
        read -r reconfig_bankofai <&3
        if [[ ! "$reconfig_bankofai" =~ ^[Yy]$ ]]; then
            echo ""
            return 0
        fi
    fi

    echo -ne "${INFO}?${NC} Enter BANKOFAI_API_KEY ${MUTED}(optional, hidden)${NC}: "
    read -rs bankofai_api_key <&3
    echo ""

    if [ -n "$bankofai_api_key" ]; then
        mkdir -p "$(dirname "$bankofai_config")"
        BANKOFAI_API_KEY="$bankofai_api_key" BANKOFAI_CONFIG="$bankofai_config" $PYTHON_CMD - <<'PY'
import json
import os

config_path = os.environ["BANKOFAI_CONFIG"]
api_key = os.environ["BANKOFAI_API_KEY"]
payload = {
    "api_key": api_key,
    "base_url": "https://chat.ainft.com"
}
with open(config_path, "w") as f:
    json.dump(payload, f, indent=2)
PY
        chmod 600 "$bankofai_config"
        echo -e "${SUCCESS}✓ BANK OF AI config saved to $bankofai_config${NC}"
        echo -e "${MUTED}  File permissions: 600 (owner read/write only)${NC}"
    else
        echo -e "${WARN}No BANK OF AI API key entered, skipping local BANK OF AI configuration${NC}"
        echo -e "${INFO}Configure later by creating $bankofai_config:${NC}"
        echo -e "${MUTED}  {\"api_key\": \"YOUR_BANKOFAI_API_KEY\"}${NC}"
    fi

    echo ""
}

configure_tronscan_api_key() {
    echo ""
    echo -e "${BOLD}TronScan API Key Configuration${NC}"
    echo -e "${MUTED}tronscan-skill requires TRONSCAN_API_KEY in the shell environment.${NC}"
    echo ""

    if [ -n "${TRONSCAN_API_KEY:-}" ]; then
        echo -e "${SUCCESS}✓ TRONSCAN_API_KEY already set in environment${NC}"
        echo ""
        return 0
    fi

    echo -e "${INFO}Add this to your shell profile (~/.zshrc or ~/.bashrc):${NC}"
    echo -e "${MUTED}export TRONSCAN_API_KEY=\"your-api-key-here\"${NC}"
    echo -e "${MUTED}Get a free key at: https://tronscan.org/#/myaccount/apiKeys${NC}"
    echo ""
}

copy_skill() {
    local skill_id="$1"
    local target_dir="$2"
    
    local skill_label
    skill_label=$(pretty_skill_name "$skill_id")
    echo -e "${INFO}Installing ${BOLD}$skill_label${NC}${INFO}...${NC}"
    
    if [ ! -d "$TEMP_DIR/$skill_id" ]; then
        echo -e "${ERROR}✗ Skill $skill_id not found in repository${NC}"
        return 1
    fi
    
    if [ ! -f "$TEMP_DIR/$skill_id/SKILL.md" ]; then
        echo -e "${ERROR}✗ $skill_id/SKILL.md not found${NC}"
        return 1
    fi
    
    if [ -d "$target_dir/$skill_id" ]; then
        echo -e "${WARN}⚠ $skill_label already exists${NC}"
        echo -ne "${INFO}?${NC} Overwrite? ${MUTED}(y/N)${NC}: "
        read -r confirm <&3
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${MUTED}  Skipped $skill_label${NC}"
            return 0
        fi
        rm -rf "$target_dir/$skill_id"
    fi
    
    mkdir -p "$target_dir"
    cp -r "$TEMP_DIR/$skill_id" "$target_dir/"
    
    # Install npm dependencies if package.json exists
    if [ -f "$target_dir/$skill_id/package.json" ]; then
        echo -e "${MUTED}  Installing npm dependencies...${NC}"
        (cd "$target_dir/$skill_id" && npm install --silent 2>/dev/null) || echo -e "${WARN}  ⚠ npm install failed (non-critical)${NC}"
    fi

    if [ "$skill_id" = "sunperp" ]; then
        echo ""
        echo -e "${WARN}sunperp depends on TRON_PRIVATE_KEY.${NC}"
        echo -e "${MUTED}Please ensure TRON_PRIVATE_KEY is configured before using sunperp.${NC}"
        echo ""
    fi
    
    # Special handling for x402-payment: configure gasfree API credentials
    if [ "$skill_id" = "x402-payment" ]; then
        echo ""
        echo -e "${BOLD}Gasfree API Configuration${NC}"
        echo -e "${MUTED}x402-payment uses Gasfree API for gasless transactions on TRON${NC}"
        echo ""

        local x402_config="$HOME/.x402-config.json"

        # Check if config already exists with valid keys
        if [ -f "$x402_config" ]; then
            local has_keys
            has_keys=$($PYTHON_CMD -c "
import json, sys
try:
    c = json.load(open('$x402_config'))
    if c.get('gasfree_api_key') and c.get('gasfree_api_secret'):
        print('yes')
    else:
        print('no')
except Exception:
    print('no')
" 2>/dev/null)

            if [ "$has_keys" = "yes" ]; then
                echo -e "${SUCCESS}✓ Gasfree API credentials already configured${NC}"
                echo -e "${MUTED}  Config: $x402_config${NC}"
                echo ""
                echo -ne "${INFO}?${NC} Reconfigure Gasfree API credentials? ${MUTED}(y/N)${NC}: "
                read -r reconfig_gasfree <&3
                if [[ ! "$reconfig_gasfree" =~ ^[Yy]$ ]]; then
                    echo ""
                fi
            fi
        fi

        # Prompt for credentials if not yet configured or user wants to reconfigure
        if [ ! -f "$x402_config" ] || [ "${has_keys:-no}" != "yes" ] || [[ "${reconfig_gasfree:-N}" =~ ^[Yy]$ ]]; then
            echo -ne "${INFO}?${NC} Enter GASFREE_API_KEY ${MUTED}(optional)${NC}: "
            read -r gasfree_api_key <&3

            echo -ne "${INFO}?${NC} Enter GASFREE_API_SECRET ${MUTED}(optional, hidden)${NC}: "
            read -rs gasfree_api_secret <&3
            echo ""

            if [ -n "$gasfree_api_key" ] && [ -n "$gasfree_api_secret" ]; then
                $PYTHON_CMD -c "
import json
config = {'gasfree_api_key': '$gasfree_api_key', 'gasfree_api_secret': '$gasfree_api_secret'}
with open('$x402_config', 'w') as f:
    json.dump(config, f, indent=2)
"
                chmod 600 "$x402_config"
                echo -e "${SUCCESS}✓ Gasfree API credentials saved to $x402_config${NC}"
                echo -e "${MUTED}  File permissions: 600 (owner read/write only)${NC}"
            else
                echo -e "${WARN}Incomplete credentials, skipping Gasfree configuration${NC}"
                echo -e "${INFO}Configure later by creating $x402_config:${NC}"
                echo -e "${MUTED}  {\"gasfree_api_key\": \"YOUR_KEY\", \"gasfree_api_secret\": \"YOUR_SECRET\"}${NC}"
            fi
        fi

        echo ""
    fi

    if [ "$skill_id" = "recharge-skill" ]; then
        configure_bankofai_api_key
    fi

    if [ "$skill_id" = "tronscan-skill" ]; then
        configure_tronscan_api_key
    fi

    if [ -f "$target_dir/$skill_id/SKILL.md" ]; then
        echo -e "${SUCCESS}✓ $skill_label installed successfully${NC}"
        INSTALLED_SKILLS+=("$skill_label")
        return 0
    else
        echo -e "${ERROR}✗ Installation failed${NC}"
        return 1
    fi
}

# --- Main Logic ---

echo -e "${ACCENT}${BOLD}"
echo "  🦞 OpenClaw Extension Installer (by BANK OF AI)"
echo -e "${NC}${ACCENT_DIM}  $TAGLINE${NC}"
echo ""

check_env

# Ensure config directory exists
mkdir -p "$MCP_CONFIG_DIR"

# Choose installation mode (Normal / Clean)
choose_install_mode

# Step 0: AgentWallet setup
setup_agent_wallet

# --- Step 1: MCP Server Configuration ---

echo ""
echo -e "${BOLD}Step 1: MCP Server Configuration${NC}"
echo ""

SERVER_OPTIONS=(
    "mcp-server-tron - Interact with TRON blockchain (Wallets, Transactions, Smart Contracts)"
    "bnbchain-mcp - BNB Chain official MCP (Multi-chain: BSC, opBNB, Ethereum, Greenfield)"
    "bankofai-recharge - BANK OF AI recharge MCP (remote recharge tools)"
)
SERVER_IDS=(
    "mcp-server-tron"
    "bnbchain-mcp"
    "bankofai-recharge"
)

SELECTED_INDICES=()
multiselect "Select MCP Servers to install:" SELECTED_INDICES "${SERVER_OPTIONS[@]}"

if [ ${#SELECTED_INDICES[@]} -eq 0 ]; then
    echo -e "${WARN}No MCP servers selected.${NC}"
    SKIP_MCP=true
else
    SKIP_MCP=false
    
    for idx in "${SELECTED_INDICES[@]}"; do
        SERVER_ID="${SERVER_IDS[$idx]}"

        echo ""
        echo -e "${BOLD}Configuring $SERVER_ID...${NC}"

        case "$SERVER_ID" in
            "mcp-server-tron")
                 echo -e "${INFO}This step configures network access for TRON MCP.${NC}"
                 ask_input "Enter TRONGRID_API_KEY" TRON_API_KEY 1 "Optional but recommended for reliable network access."
                 echo -e "${MUTED}Saving configuration...${NC}"

                 TRON_API_KEY_VAL=$(json_string_or_null "$TRON_API_KEY")

                 JSON_PAYLOAD=$(cat <<EOF
{
  "command": "npx",
  "args": ["-y", "@bankofai/mcp-server-tron@1.1.7-beta"],
  "env": {
    "TRONGRID_API_KEY": $TRON_API_KEY_VAL
  }
}
EOF
)

                 write_server_config "$SERVER_ID" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"
                 ;;
            
            "bnbchain-mcp")
                 echo -e "${WARN}bnbchain-mcp currently does not support AgentWallet.${NC}"
                 echo -e "${WARN}This server still uses PRIVATE_KEY configuration.${NC}"
                 echo ""
                 echo -e "${WARN}!!! SECURITY WARNING !!!${NC}"
                 echo -e "${WARN}Sensitive keys will be saved in PLAINTEXT to: ${INFO}$MCP_CONFIG_FILE${NC}"
                 echo -e "${WARN}DO NOT allow AI agents to scan this file.${NC}"
                 echo ""
                 
                 # Ask for credential storage method
                 echo -e "${BOLD}How would you like to store your credentials?${NC}"
                 echo -e "  ${INFO}1)${NC} Save in config file (${INFO}$MCP_CONFIG_FILE${NC})"
                 echo -e "     ${MUTED}Keys stored in plaintext, convenient but less secure${NC}"
                 echo -e "  ${INFO}2)${NC} Use environment variables"
                 echo -e "     ${MUTED}Keys read from shell environment, more secure${NC}"
                 echo ""
                 echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-2, default: 2)${NC}: "
                 
                 read -r cred_choice <&3
                 cred_choice=${cred_choice:-2}
                 
                 echo ""
                 
                 if [ "$cred_choice" = "1" ]; then
                     # Store in config file
                     ask_input "Enter BNB Chain PRIVATE_KEY" BNB_KEY 1 "Your BNB Chain wallet private key (with or without 0x prefix). Required for signing transactions."
                     ask_input "Enter LOG_LEVEL" BNB_LOG_LEVEL 0 "Log level: DEBUG, INFO, WARN, ERROR (default: INFO)"

                     echo -e "${MUTED}Saving configuration...${NC}"

                     # Ensure private key has 0x prefix
                     if [ -n "$BNB_KEY" ]; then
                         if [[ ! "$BNB_KEY" =~ ^0x ]]; then
                             BNB_KEY="0x${BNB_KEY}"
                             echo -e "${INFO}Added 0x prefix to private key${NC}"
                         fi
                         BNB_KEY_VAL="\"$BNB_KEY\""
                     else
                         BNB_KEY_VAL="null"
                     fi

                     BNB_LOG_LEVEL_VAL="\"${BNB_LOG_LEVEL:-INFO}\""

                     JSON_PAYLOAD=$(cat <<EOF
{
  "command": "npx",
  "args": ["-y", "@bnb-chain/mcp@latest"],
  "env": {
    "PRIVATE_KEY": $BNB_KEY_VAL,
    "LOG_LEVEL": $BNB_LOG_LEVEL_VAL
  }
}
EOF
)
                 else
                     # Use environment variables
                     echo -e "${INFO}Using environment variables for credentials.${NC}"
                     echo -e "${MUTED}The MCP server will read from your shell environment.${NC}"
                     echo ""
                     echo -e "${BOLD}Add these to your shell profile (~/.zshrc, ~/.bashrc, etc.):${NC}"
                     echo -e "${MUTED}export PRIVATE_KEY=\"0x_your_private_key_here\"${NC}"
                     echo -e "${MUTED}export LOG_LEVEL=\"INFO\"${NC}"
                     echo ""
                     
                     JSON_PAYLOAD=$(cat <<EOF
{
  "command": "npx",
  "args": ["-y", "@bnb-chain/mcp@latest"]
}
EOF
)
                 fi
                 
                 write_server_config "$SERVER_ID" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"
                 ;;

            "bankofai-recharge")
                 JSON_PAYLOAD=$(cat <<EOF
{
  "baseUrl": "https://recharge.bankofai.io/mcp"
}
EOF
)

                 write_server_config "$SERVER_ID" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"
                 ;;
        esac

        echo -e "${SUCCESS}✓ Configuration saved for $SERVER_ID.${NC}"
    done
fi

# --- Step 2: Skills Installation from GitHub ---

echo ""
echo -e "${BOLD}Step 2: Skills Installation from GitHub${NC}"
echo ""

if ! clone_skills_repo; then
    echo -e "${WARN}Skipping skills installation due to clone failure.${NC}"
else
    # Discover available skills
    SKILL_OPTIONS=()
    SKILL_IDS=()

    for dir in "$TEMP_DIR"/*; do
        if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
            skill_name=$(basename "$dir")
            skill_label=$(pretty_skill_name "$skill_name")
            
            # Skip installer directory
            if [ "$skill_name" = "installer" ]; then
                continue
            fi
            
            # Read description
            description=$(head -n 1 "$dir/SKILL.md" | sed 's/^#* *//' | sed 's/^---$//')
            
            if [ -z "$description" ] || [ "$description" = "---" ]; then
                description=$(grep "^description:" "$dir/SKILL.md" 2>/dev/null | head -n 1 | sed 's/^description: *//' || echo "")
            fi
            
            if [ -z "$description" ]; then
                description="TRON skill"
            fi
            
            SKILL_IDS+=("$skill_name")
            SKILL_OPTIONS+=("$skill_label - $description")
        fi
    done

    if [ ${#SKILL_OPTIONS[@]} -eq 0 ]; then
        echo -e "${WARN}No skills found in repository.${NC}"
    else
        SELECTED_SKILL_INDICES=()
        multiselect "Select skills to install:" SELECTED_SKILL_INDICES "${SKILL_OPTIONS[@]}"

        if [ ${#SELECTED_SKILL_INDICES[@]} -eq 0 ]; then
            echo -e "${MUTED}No skills selected.${NC}"
        else
            echo ""
            select_install_target
            
            echo -e "${BOLD}Installing skills...${NC}"
            echo ""

            for idx in "${SELECTED_SKILL_INDICES[@]}"; do
                skill_id="${SKILL_IDS[$idx]}"
                copy_skill "$skill_id" "$TARGET_DIR"
            done
        fi
    fi
fi

# --- Final Summary ---
echo ""
echo -e "${ACCENT}${BOLD}═══════════════════════════════════════${NC}"
echo -e "${ACCENT}${BOLD}  Installation Complete!${NC}"
echo -e "${ACCENT}${BOLD}═══════════════════════════════════════${NC}"
echo ""

if [ "$SKIP_MCP" = false ]; then
    echo -e "${SUCCESS}✓${NC} ${BOLD}MCP Server configured${NC}"
    echo -e "  ${INFO}Config file: ${BOLD}$MCP_CONFIG_FILE${NC}"
    echo -e "  ${WARN}→ Secure your config: ${BOLD}chmod 600 $MCP_CONFIG_FILE${NC}"
    echo ""
fi

if [ ${#INSTALLED_SKILLS[@]} -gt 0 ]; then
    echo -e "${SUCCESS}✓${NC} ${BOLD}Installed skills:${NC}"
    for skill in "${INSTALLED_SKILLS[@]}"; do
        echo -e "  ${SUCCESS}•${NC} ${INFO}$skill${NC}"
    done
    echo -e "  ${INFO}Location: ${BOLD}$TARGET_DIR${NC}"
    echo ""
fi

if [ ${#INSTALLED_SKILLS[@]} -gt 0 ]; then
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  ${INFO}1.${NC} ${BOLD}Restart OpenClaw and start a new session${NC} to load new skills"
    echo ""
    echo -e "  ${INFO}2.${NC} ${BOLD}Test the skills:${NC}"
    
    for skill in "${INSTALLED_SKILLS[@]}"; do
        case "$skill" in
            "sunswap")
                echo -e "     ${MUTED}\"Read the sunswap skill and help me swap 100 USDT to TRX\"${NC}"
                ;;
            "recharge-skill")
                echo -e "     ${MUTED}\"Read the recharge-skill and recharge my BANK OF AI account with 1 USDT\"${NC}"
                ;;
            "tronscan-skill")
                echo -e "     ${MUTED}\"Read the tronscan-skill and look up the latest TRON block\"${NC}"
                ;;
            "x402-payment")
                echo -e "     ${MUTED}\"Read the x402-payment skill and explain how it works\"${NC}"
                ;;
        esac
    done
    echo ""
fi

echo -e "${MUTED}Repository: https://github.com/BofAI/openclaw-extension${NC}"
echo -e "${MUTED}Skills: https://github.com/BofAI/skills${NC}"
echo ""
