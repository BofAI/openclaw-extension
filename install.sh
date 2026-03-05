#!/bin/bash
set -euo pipefail

# OpenClaw Extension Installer (by BankofAI)
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
TMPFILES=()
TEMP_DIR=""
INSTALLED_SKILLS=()

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
    echo -e "${INFO}Cloning skills repository...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    if ! git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR" 2>/dev/null; then
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

configure_8004_key() {
    echo ""
    echo -e "${BOLD}8004 Private Key Configuration${NC}"
    echo -e "${MUTED}8004 scripts need a private key for write operations (register, feedback, etc.)${NC}"
    echo ""
    
    # Check if key already exists
    local key_file="$HOME/.clawdbot/wallets/.deployer_pk"
    local has_env_key=false
    
    if [ -n "${TRON_PRIVATE_KEY:-}" ] || [ -n "${PRIVATE_KEY:-}" ]; then
        has_env_key=true
    fi
    
    if [ -f "$key_file" ] || [ "$has_env_key" = true ]; then
        echo -e "${SUCCESS}✓ Private key already configured${NC}"
        if [ -f "$key_file" ]; then
            echo -e "${MUTED}  Found at: $key_file${NC}"
        fi
        if [ "$has_env_key" = true ]; then
            echo -e "${MUTED}  Found in environment variable${NC}"
        fi
        echo ""
        echo -ne "${INFO}?${NC} Reconfigure private key? ${MUTED}(y/N)${NC}: "
        read -r reconfig <&3
        if [[ ! "$reconfig" =~ ^[Yy]$ ]]; then
            return 0
        fi
        echo ""
    fi
    
    echo -e "${BOLD}How would you like to configure your private key?${NC}"
    echo -e "  ${INFO}1)${NC} Save to file (${INFO}~/.clawdbot/wallets/.deployer_pk${NC}) ${SUCCESS}[Recommended]${NC}"
    echo -e "     ${MUTED}Persistent, shared with 8004-skill${NC}"
    echo -e "  ${INFO}2)${NC} Set environment variable (${INFO}TRON_PRIVATE_KEY${NC})"
    echo -e "     ${MUTED}You'll need to add to ~/.zshrc or ~/.bashrc manually${NC}"
    echo -e "  ${INFO}3)${NC} Skip (configure later)"
    echo ""
    echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-3, default: 1)${NC}: "
    
    read -r key_choice <&3
    key_choice=${key_choice:-1}
    
    echo ""
    
    case $key_choice in
        1)
            echo -e "${WARN}⚠ Your private key will be saved in PLAINTEXT${NC}"
            echo -e "${WARN}   File: $key_file${NC}"
            echo ""
            echo -ne "${INFO}?${NC} Enter your TRON private key ${MUTED}(64 hex characters)${NC}: "
            read -rs private_key <&3
            echo ""
            
            if [ -z "$private_key" ]; then
                echo -e "${WARN}No private key entered, skipping configuration${NC}"
                return 0
            fi
            
            # Validate key format (basic check)
            if [ ${#private_key} -ne 64 ]; then
                echo -e "${WARN}⚠ Warning: Private key should be 64 characters${NC}"
                echo -ne "${INFO}?${NC} Continue anyway? ${MUTED}(y/N)${NC}: "
                read -r continue_anyway <&3
                if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                    echo -e "${MUTED}Skipping private key configuration${NC}"
                    return 0
                fi
            fi
            
            # Save to file
            mkdir -p "$(dirname "$key_file")"
            echo "$private_key" > "$key_file"
            chmod 600 "$key_file"
            
            echo -e "${SUCCESS}✓ Private key saved to $key_file${NC}"
            echo -e "${MUTED}  File permissions: 600 (owner read/write only)${NC}"
            ;;
            
        2)
            echo -e "${INFO}Add this to your shell profile (~/.zshrc or ~/.bashrc):${NC}"
            echo -e "${MUTED}export TRON_PRIVATE_KEY=\"your_private_key_here\"${NC}"
            echo ""
            echo -e "${MUTED}Then reload your shell: source ~/.zshrc${NC}"
            ;;
            
        3)
            echo -e "${MUTED}Skipping private key configuration${NC}"
            echo -e "${INFO}Configure later with one of these methods:${NC}"
            echo -e "${MUTED}  1. File: echo \"your_key\" > ~/.clawdbot/wallets/.deployer_pk${NC}"
            echo -e "${MUTED}  2. Env:  export TRON_PRIVATE_KEY=\"your_key\"${NC}"
            ;;
            
        *)
            echo -e "${WARN}Invalid choice, skipping configuration${NC}"
            ;;
    esac
    
    echo ""
}

copy_skill() {
    local skill_id="$1"
    local target_dir="$2"
    
    echo -e "${INFO}Installing ${BOLD}$skill_id${NC}${INFO}...${NC}"
    
    if [ ! -d "$TEMP_DIR/$skill_id" ]; then
        echo -e "${ERROR}✗ Skill $skill_id not found in repository${NC}"
        return 1
    fi
    
    if [ ! -f "$TEMP_DIR/$skill_id/SKILL.md" ]; then
        echo -e "${ERROR}✗ $skill_id/SKILL.md not found${NC}"
        return 1
    fi
    
    if [ -d "$target_dir/$skill_id" ]; then
        echo -e "${WARN}⚠ $skill_id already exists${NC}"
        echo -ne "${INFO}?${NC} Overwrite? ${MUTED}(y/N)${NC}: "
        read -r confirm <&3
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${MUTED}  Skipped $skill_id${NC}"
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
    
    # Special handling for 8004-skill: configure private key
    if [ "$skill_id" = "8004-skill" ]; then
        configure_8004_key
    fi
    
    # Special handling for sunswap: remind about private key
    if [ "$skill_id" = "sunswap" ]; then
        echo ""
        echo -e "${BOLD}SunSwap Private Key Configuration${NC}"
        echo -e "${MUTED}SunSwap scripts need a private key for swap operations${NC}"
        echo ""
        
        # Check if key already exists
        local key_file="$HOME/.clawdbot/wallets/.deployer_pk"
        local has_env_key=false
        
        if [ -n "${TRON_PRIVATE_KEY:-}" ] || [ -n "${PRIVATE_KEY:-}" ]; then
            has_env_key=true
        fi
        
        if [ -f "$key_file" ] || [ "$has_env_key" = true ]; then
            echo -e "${SUCCESS}✓ Private key already configured (shared with 8004-skill)${NC}"
            if [ -f "$key_file" ]; then
                echo -e "${MUTED}  Found at: $key_file${NC}"
            fi
            if [ "$has_env_key" = true ]; then
                echo -e "${MUTED}  Found in environment variable${NC}"
            fi
        else
            echo -e "${INFO}Configure private key using one of these methods:${NC}"
            echo -e "${MUTED}  1. File: echo \"your_key\" > ~/.clawdbot/wallets/.deployer_pk && chmod 600 ~/.clawdbot/wallets/.deployer_pk${NC}"
            echo -e "${MUTED}  2. Env:  export TRON_PRIVATE_KEY=\"your_key\"${NC}"
            echo ""
            echo -e "${INFO}Or install 8004-skill which will guide you through the setup${NC}"
        fi
        echo ""
    fi
    
    if [ -f "$target_dir/$skill_id/SKILL.md" ]; then
        echo -e "${SUCCESS}✓ $skill_id installed successfully${NC}"
        INSTALLED_SKILLS+=("$skill_id")
        return 0
    else
        echo -e "${ERROR}✗ Installation failed${NC}"
        return 1
    fi
}

install_security_guidelines() {
    local workspace_dir="$HOME/.openclaw/workspace"
    local web3_workspace="$HOME/.openclaw/workspace-web3"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local workspace_template_dir="$script_dir/workspace"
    
    # Check if workspace template exists
    if [ ! -d "$workspace_template_dir" ]; then
        echo -e "${WARN}⚠ workspace template not found, skipping workspace setup${NC}"
        return 0
    fi
    
    echo -e "${BOLD}OpenClaw Workspace Setup${NC}"
    echo ""
    
    # Check if workspace already exists
    if [ -d "$workspace_dir" ] && [ "$(ls -A $workspace_dir 2>/dev/null)" ]; then
        echo -e "${WARN}⚠ Workspace already exists: $workspace_dir${NC}"
        echo ""
        echo -e "Choose an option:"
        echo -e "  ${INFO}1)${NC} Create new Web3 workspace ${SUCCESS}[Recommended]${NC}"
        echo -e "     ${MUTED}Install to ~/.openclaw/workspace-web3 (keeps your current workspace)${NC}"
        echo -e "     ${MUTED}Auto-switch to new workspace${NC}"
        echo -e "  ${INFO}2)${NC} Overwrite existing workspace"
        echo -e "     ${MUTED}Replace all files in ~/.openclaw/workspace with Web3-enhanced versions${NC}"
        echo ""
        echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-2, default: 1)${NC}: "
        
        read -r workspace_choice <&3
        workspace_choice=${workspace_choice:-1}
        
        case $workspace_choice in
            1)
                # Create new Web3 workspace (default)
                echo ""
                echo -e "${INFO}Creating new Web3 workspace...${NC}"
                
                if [ -d "$web3_workspace" ] && [ "$(ls -A $web3_workspace 2>/dev/null)" ]; then
                    echo -e "${WARN}⚠ Web3 workspace already exists: $web3_workspace${NC}"
                    echo -ne "${INFO}?${NC} Overwrite? ${MUTED}(y/N)${NC}: "
                    read -r confirm <&3
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        echo -e "${MUTED}  Cancelled${NC}"
                        return 0
                    fi
                fi
                
                # Create Web3 workspace directory
                mkdir -p "$web3_workspace"
                
                # Copy all template files
                cp -f "$workspace_template_dir"/* "$web3_workspace/"
                
                echo -e "${SUCCESS}✓ New Web3 workspace created${NC}"
                echo -e "${MUTED}  Location: $web3_workspace${NC}"
                echo ""
                
                # Auto-switch to new workspace
                echo -e "${INFO}Switching to new workspace...${NC}"
                if openclaw config set agents.defaults.workspace "$web3_workspace" 2>/dev/null; then
                    echo -e "${SUCCESS}✓ Workspace switched successfully${NC}"
                    echo -e "${MUTED}  Active workspace: $web3_workspace${NC}"
                    echo ""
                    echo -e "${INFO}Restarting OpenClaw gateway...${NC}"
                    if openclaw gateway restart 2>/dev/null; then
                        echo -e "${SUCCESS}✓ Gateway restarted${NC}"
                    else
                        echo -e "${WARN}⚠ Gateway restart failed. Restart manually:${NC}"
                        echo -e "${MUTED}  openclaw gateway restart${NC}"
                    fi
                else
                    echo -e "${WARN}⚠ Auto-switch failed. Switch manually:${NC}"
                    echo -e "${MUTED}  openclaw config set agents.defaults.workspace $web3_workspace${NC}"
                    echo -e "${MUTED}  openclaw gateway restart${NC}"
                fi
                echo ""
                echo -e "${INFO}To switch back to your original workspace:${NC}"
                echo -e "${MUTED}  openclaw config set agents.defaults.workspace $workspace_dir${NC}"
                echo -e "${MUTED}  openclaw gateway restart${NC}"
                
                workspace_dir="$web3_workspace"
                ;;
            2)
                # Overwrite existing workspace
                echo ""
                echo -e "${WARN}⚠ This will overwrite ALL files in your workspace${NC}"
                echo -ne "${INFO}?${NC} Are you sure? ${MUTED}(y/N)${NC}: "
                read -r confirm <&3
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${MUTED}  Cancelled${NC}"
                    return 0
                fi
                
                # Overwrite all files
                cp -f "$workspace_template_dir"/* "$workspace_dir/"
                
                echo -e "${SUCCESS}✓ Workspace overwritten${NC}"
                echo -e "${MUTED}  Location: $workspace_dir${NC}"
                ;;
            *)
                echo -e "${WARN}Invalid choice, using default (create new workspace)${NC}"
                
                # Default: create new workspace
                mkdir -p "$web3_workspace"
                cp -f "$workspace_template_dir"/* "$web3_workspace/"
                
                echo -e "${SUCCESS}✓ New Web3 workspace created${NC}"
                echo -e "${MUTED}  Location: $web3_workspace${NC}"
                echo ""
                echo -e "${INFO}Switch to this workspace:${NC}"
                echo -e "${MUTED}  openclaw config set agents.defaults.workspace $web3_workspace${NC}"
                echo -e "${MUTED}  openclaw gateway restart${NC}"
                
                workspace_dir="$web3_workspace"
                ;;
        esac
    else
        # No existing workspace - create new Web3 workspace
        echo -e "${INFO}No existing workspace found. Creating new Web3 workspace...${NC}"
        echo ""
        
        # Create Web3 workspace directory
        mkdir -p "$web3_workspace"
        
        # Copy all template files
        cp -f "$workspace_template_dir"/* "$web3_workspace/"
        
        echo -e "${SUCCESS}✓ New Web3 workspace created${NC}"
        echo -e "${MUTED}  Location: $web3_workspace${NC}"
        echo ""
        
        # Auto-switch to new workspace
        echo -e "${INFO}Setting as default workspace...${NC}"
        if openclaw config set agents.defaults.workspace "$web3_workspace" 2>/dev/null; then
            echo -e "${SUCCESS}✓ Workspace configured successfully${NC}"
            echo -e "${MUTED}  Active workspace: $web3_workspace${NC}"
            echo ""
            echo -e "${INFO}Restarting OpenClaw gateway...${NC}"
            if openclaw gateway restart 2>/dev/null; then
                echo -e "${SUCCESS}✓ Gateway restarted${NC}"
            else
                echo -e "${WARN}⚠ Gateway restart failed. Restart manually:${NC}"
                echo -e "${MUTED}  openclaw gateway restart${NC}"
            fi
        else
            echo -e "${WARN}⚠ Auto-config failed. Configure manually:${NC}"
            echo -e "${MUTED}  openclaw config set agents.defaults.workspace $web3_workspace${NC}"
            echo -e "${MUTED}  openclaw gateway restart${NC}"
        fi
        
        workspace_dir="$web3_workspace"
    fi
    
    # Show installed files
    echo ""
    echo -e "${MUTED}  Files installed:${NC}"
    echo -e "${MUTED}    • AGENTS.md (Web3-enhanced)${NC}"
    echo -e "${MUTED}    • BOOTSTRAP.md (first-run setup)${NC}"
    echo -e "${MUTED}    • SOUL.md, USER.md, IDENTITY.md${NC}"
    echo -e "${MUTED}    • TOOLS.md (Web3-enhanced)${NC}"
    echo -e "${MUTED}    • HEARTBEAT.md${NC}"
    echo ""
    echo -e "${INFO}OpenClaw will automatically load these files in new sessions${NC}"
    
    if [ -f "$workspace_dir/BOOTSTRAP.md" ]; then
        echo -e "${INFO}Next: Start OpenClaw and follow BOOTSTRAP.md to set up your identity${NC}"
    fi
}

# --- Main Logic ---

echo -e "${ACCENT}${BOLD}"
echo "  🦞 OpenClaw Extension Installer (by BankofAI)"
echo -e "${NC}${ACCENT_DIM}  $TAGLINE${NC}"
echo ""

check_env

# Ensure config directory exists
mkdir -p "$MCP_CONFIG_DIR"

npx clawhub install --force mcporter

# --- Step 1: OpenClaw Workspace Setup ---

echo -e "${BOLD}Step 1: OpenClaw Workspace Setup${NC}"
echo ""
install_security_guidelines

# --- Step 2: MCP Server Configuration ---

echo ""
echo -e "${BOLD}Step 2: MCP Server Configuration${NC}"
echo ""

SERVER_OPTIONS=(
    "mcp-server-tron - Interact with TRON blockchain (Wallets, Transactions, Smart Contracts)"
    "bnbchain-mcp - BNB Chain official MCP (Multi-chain: BSC, opBNB, Ethereum, Greenfield)"
)
SERVER_IDS=(
    "mcp-server-tron"
    "bnbchain-mcp"
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
                 echo -e "${BOLD}Agent-wallet setup (encrypted keystore):${NC}"
                 echo -e "${MUTED}Private keys are encrypted at rest and never exposed in plaintext.${NC}"
                 echo ""
                 echo -e "${MUTED}If you haven't initialized a wallet yet, run:${NC}"
                 echo -e "${INFO}  npx agent-wallet init --dir ~/.agent-wallet${NC}"
                 echo -e "${INFO}  npx agent-wallet add --dir ~/.agent-wallet${NC}"
                 echo -e "${INFO}  npx agent-wallet list --dir ~/.agent-wallet${NC}"
                 echo ""

                 ask_input "Enter AGENT_WALLET_DIR" AW_DIR 0 "Path to agent-wallet directory (default: ~/.agent-wallet)"
                 if [ -z "$AW_DIR" ]; then AW_DIR="$HOME/.agent-wallet"; fi

                 ask_input "Enter AGENT_WALLET_PASSWORD" AW_PASSWORD 1 "Master password for agent-wallet"

                 ask_input "Enter AGENT_WALLET_ID" AW_ID 0 "Wallet ID (leave empty to auto-select first wallet)"

                 ask_input "Enter TRONGRID_API_KEY" TRON_API_KEY 1 "TronGrid API Key for reliable mainnet access"

                 echo -e "${MUTED}Saving configuration...${NC}"

                 AW_DIR_VAL="\"$AW_DIR\""
                 AW_PASSWORD_VAL="\"$AW_PASSWORD\""
                 if [ -z "$AW_PASSWORD" ]; then AW_PASSWORD_VAL="null"; fi
                 AW_ID_VAL="\"$AW_ID\""
                 if [ -z "$AW_ID" ]; then AW_ID_VAL="null"; fi
                 TRON_API_KEY_VAL="\"$TRON_API_KEY\""
                 if [ -z "$TRON_API_KEY" ]; then TRON_API_KEY_VAL="null"; fi

                 JSON_PAYLOAD=$(cat <<EOF
{
  "command": "npx",
  "args": ["-y", "@bankofai/mcp-server-tron"],
  "env": {
    "AGENT_WALLET_DIR": $AW_DIR_VAL,
    "AGENT_WALLET_PASSWORD": $AW_PASSWORD_VAL,
    "AGENT_WALLET_ID": $AW_ID_VAL,
    "TRONGRID_API_KEY": $TRON_API_KEY_VAL
  }
}
EOF
)
                 write_server_config "$SERVER_ID" "$JSON_PAYLOAD" "$MCP_CONFIG_FILE"
                 ;;
            
            "bnbchain-mcp")
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
        esac

        echo -e "${SUCCESS}✓ Configuration saved for $SERVER_ID.${NC}"
    done
fi

# --- Step 3: Skills Installation from GitHub ---

echo ""
echo -e "${BOLD}Step 3: Skills Installation from GitHub${NC}"
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
            SKILL_OPTIONS+=("$skill_name - $description")
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
    
    # Check if AGENTS.md was installed
    if [ -f "$HOME/.openclaw/workspace/AGENTS.md" ]; then
        echo -e "${SUCCESS}✓${NC} ${BOLD}Security guidelines installed${NC}"
        echo -e "  ${INFO}Location: ${BOLD}$HOME/.openclaw/workspace/AGENTS.md${NC}"
        echo -e "  ${MUTED}OpenClaw will automatically load these rules${NC}"
        echo ""
    fi
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
            "8004-skill")
                echo -e "     ${MUTED}\"Read the 8004-skill and register my AI agent on TRON\"${NC}"
                ;;
            "x402-payment")
                echo -e "     ${MUTED}\"Read the x402-payment skill and explain how it works\"${NC}"
                ;;
            "x402-payment-demo")
                echo -e "     ${MUTED}\"Read the x402-payment-demo skill and run the demo\"${NC}"
                ;;
        esac
    done
    echo ""
fi

echo -e "${MUTED}Repository: https://github.com/BofAI/openclaw-extension${NC}"
echo -e "${MUTED}Skills: https://github.com/BofAI/skills${NC}"
echo ""
