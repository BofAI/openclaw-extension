#!/bin/bash
set -euo pipefail

# OpenClaw Extension Installer (by BANK OF AI)
# Installs MCP servers via npx add-mcp and skills via npx skills add

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
AGENT_WALLET_VERSION="2.3.1"
SKILLS_REPO="https://github.com/BofAI/skills/tree/v1.5.6"
INSTALLED_SKILLS=()
CLEAN_INSTALL=false
SKILLS_GLOBAL_FLAG=""

# --- Cleanup ---
cleanup() {
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

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

# --- Node.js JSON Helpers ---

node_json_merge() {
    local server_id="$1"
    local env_json="$2"
    local config_file="$3"

    MCP_FILE="$config_file" SERVER_ID="$server_id" ENV_JSON="$env_json" node --input-type=commonjs <<'NODESCRIPT'
const _fs = require("fs");
const f = process.env.MCP_FILE;
const sid = process.env.SERVER_ID;
const envData = JSON.parse(process.env.ENV_JSON);
let d = {};
if (_fs.existsSync(f)) {
    try { d = JSON.parse(_fs.readFileSync(f, "utf8")); } catch(e) {}
}
if (!d.mcpServers) d.mcpServers = {};
if (!d.mcpServers[sid]) d.mcpServers[sid] = {};
if (!d.mcpServers[sid].env) d.mcpServers[sid].env = {};
for (const [k, v] of Object.entries(envData)) {
    if (v === null || v === "") {
        delete d.mcpServers[sid].env[k];
    } else {
        d.mcpServers[sid].env[k] = v;
    }
}
_fs.writeFileSync(f, JSON.stringify(d, null, 2));
NODESCRIPT
}

node_json_write() {
    local file_path="$1"
    local json_content="$2"

    FILE_PATH="$file_path" JSON_CONTENT="$json_content" node --input-type=commonjs <<'NODESCRIPT'
const _fs = require("fs");
const _path = require("path");
const f = process.env.FILE_PATH;
const dir = _path.dirname(f);
if (!_fs.existsSync(dir)) _fs.mkdirSync(dir, { recursive: true });
const data = JSON.parse(process.env.JSON_CONTENT);
_fs.writeFileSync(f, JSON.stringify(data, null, 2));
NODESCRIPT
}

node_json_read() {
    local file_path="$1"
    local key="$2"

    FILE_PATH="$file_path" JSON_KEY="$key" node --input-type=commonjs <<'NODESCRIPT'
const _fs = require("fs");
const f = process.env.FILE_PATH;
const k = process.env.JSON_KEY;
try {
    const d = JSON.parse(_fs.readFileSync(f, "utf8"));
    const v = d[k];
    process.stdout.write(v ? String(v) : "");
} catch(e) {
    process.stdout.write("");
}
NODESCRIPT
}

node_json_reset_mcp() {
    local config_file="$1"

    MCP_FILE="$config_file" node --input-type=commonjs <<'NODESCRIPT'
const _fs = require("fs");
const f = process.env.MCP_FILE;
let d = {};
if (_fs.existsSync(f)) {
    try { d = JSON.parse(_fs.readFileSync(f, "utf8")); } catch(e) {}
}
d.mcpServers = {};
_fs.writeFileSync(f, JSON.stringify(d, null, 2));
NODESCRIPT
}

# --- Input Helper ---

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

# --- Clean Install ---

run_clean_install() {
    echo ""
    echo -e "${ERROR}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo -e "${ERROR}${BOLD}!!!                    CLEAN INSTALL MODE                    !!!${NC}"
    echo -e "${ERROR}${BOLD}!!!                  THIS ACTION IS IRREVERSIBLE             !!!${NC}"
    echo -e "${ERROR}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo ""
    echo -e "${WARN}The following data will be permanently deleted:${NC}"
    echo -e "  ${WARN}•${NC} ALL MCP entries in: ${INFO}$MCP_CONFIG_FILE${NC}"
    echo -e "  ${WARN}•${NC} ALL installed skills (global and workspace)"
    echo -e "  ${WARN}•${NC} x402 config file: ${INFO}$HOME/.x402-config.json${NC}"
    echo -e "  ${WARN}•${NC} BANK OF AI local config: ${INFO}$HOME/.mcporter/bankofai-config.json${NC}"
    echo -e "  ${WARN}•${NC} AgentWallet config will be overwritten by: ${INFO}agent-wallet start --override --save-runtime-secrets${NC}"
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
    node_json_reset_mcp "$MCP_CONFIG_FILE"
    npx -y skills remove -a openclaw --all -y -g </dev/null 2>/dev/null || true
    npx -y skills remove -a openclaw --all -y </dev/null 2>/dev/null || true
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
        echo -e "${SUCCESS}Clean complete — proceeding with fresh setup...${NC}"
        echo ""
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
        echo -e "${INFO}Launching: agent-wallet start --override --save-runtime-secrets${NC}"
        echo -e "${MUTED}Please complete initialization in the CLI prompts.${NC}"
        echo ""
        if ! run_agent_wallet_cli start --override --save-runtime-secrets; then
            echo -e "${ERROR}AgentWallet initialization failed in CLEAN mode.${NC}"
            exit 1
        fi
    else
        echo -e "${INFO}Launching: agent-wallet start --save-runtime-secrets${NC}"
        echo -e "${MUTED}Please complete initialization in the CLI prompts.${NC}"
        echo ""
        if ! run_agent_wallet_cli start --save-runtime-secrets; then
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
    local term_cols=80
    local previous_frame_lines=0
    local indent="      "

    if [ -r /dev/tty ] && command -v stty &> /dev/null; then
        local had_errexit=0
        case "$-" in *e*) had_errexit=1 ;; esac
        if [ $had_errexit -eq 1 ]; then set +e; fi
        term_cols=$(stty -f /dev/tty size 2>/dev/null | awk '{print $2}')
        if [ -z "$term_cols" ]; then
            term_cols=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')
        fi
        if [ $had_errexit -eq 1 ]; then set -e; fi
    fi
    if ! [[ "$term_cols" =~ ^[0-9]+$ ]]; then
        term_cols=0
    fi
    if [ "$term_cols" -lt 20 ] && command -v tput &> /dev/null; then
        term_cols=$(tput cols 2>/dev/null || echo 80)
    fi
    if ! [[ "$term_cols" =~ ^[0-9]+$ ]] || [ "$term_cols" -lt 20 ]; then
        term_cols=80
    fi

    # Initialize selection - all selected by default
    for ((i=0; i<${#options[@]}; i++)); do
        selected[i]=true
    done

    echo -e "${INFO}?${NC} ${BOLD}$prompt${NC} ${MUTED}(Space:toggle, Enter:confirm)${NC}"

    tput civis # Hide cursor

    while true; do
        if [ $previous_frame_lines -gt 0 ]; then
            tput cuu ${previous_frame_lines}
        fi
        tput ed

        local frame_lines=0

        for ((i=0; i<${#options[@]}; i++)); do
            local checkbox="[ ]"
            local color="$NC"
            local pointer="  "
            local raw="${options[i]}"
            local name="$raw"
            local desc=""
            local max_len=$((term_cols - 6))

            if [[ "$raw" == *"||"* ]]; then
                name="${raw%%||*}"
                desc="${raw#*||}"
            fi

            name=$(echo "$name" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')
            if [ ${#name} -gt $max_len ]; then
                name="${name:0:$max_len}"
            fi

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

            echo -e "${pointer}${checkbox} ${color}${name}${NC}"
            frame_lines=$((frame_lines + 1))

            if [ $i -eq $current ] && [ -n "$desc" ]; then
                local wrapped=()
                while IFS= read -r line || [ -n "$line" ]; do
                    wrapped+=("$line")
                done < <(printf '%s' "$desc" | fold -s -w $((term_cols - ${#indent} - 1)))

                for line in "${wrapped[@]}"; do
                    echo -e "${MUTED}${indent}${line}${NC}"
                    frame_lines=$((frame_lines + 1))
                done
            fi
        done

        previous_frame_lines=$frame_lines

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

# --- Skill Configuration Functions ---

configure_bankofai_api_key() {
    echo ""
    echo -e "${BOLD}recharge-skill API Key Configuration${NC}"
    echo -e "${MUTED}recharge-skill uses your local BANK OF AI API key for balance and order queries.${NC}"
    echo -e "${MUTED}Recharge requests use the remote BANK OF AI recharge MCP endpoint.${NC}"
    echo ""

    local bankofai_config="$HOME/.mcporter/bankofai-config.json"
    local has_key=""

    if [ -f "$bankofai_config" ]; then
        has_key=$(node_json_read "$bankofai_config" "api_key")
    fi

    if [ -n "$has_key" ]; then
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
        local json_content
        json_content=$(BANKOFAI_API_KEY="$bankofai_api_key" node -e '
const k = process.env.BANKOFAI_API_KEY;
console.log(JSON.stringify({ api_key: k, base_url: "https://chat.ainft.com" }));
')
        node_json_write "$bankofai_config" "$json_content"
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

configure_x402_gasfree() {
    echo ""
    echo -e "${BOLD}Gasfree API Configuration${NC}"
    echo -e "${MUTED}x402-payment uses Gasfree API for gasless transactions on TRON${NC}"
    echo ""

    local x402_config="$HOME/.x402-config.json"
    local has_keys=""
    local reconfig_gasfree="N"

    # Check if config already exists with valid keys
    if [ -f "$x402_config" ]; then
        local gasfree_key
        local gasfree_secret
        gasfree_key=$(node_json_read "$x402_config" "gasfree_api_key")
        gasfree_secret=$(node_json_read "$x402_config" "gasfree_api_secret")

        if [ -n "$gasfree_key" ] && [ -n "$gasfree_secret" ]; then
            has_keys="yes"
            echo -e "${SUCCESS}✓ Gasfree API credentials already configured${NC}"
            echo -e "${MUTED}  Config: $x402_config${NC}"
            echo ""
            echo -ne "${INFO}?${NC} Reconfigure Gasfree API credentials? ${MUTED}(y/N)${NC}: "
            read -r reconfig_gasfree <&3
            if [[ ! "$reconfig_gasfree" =~ ^[Yy]$ ]]; then
                echo ""
                return 0
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
            local json_content
            json_content=$(GASFREE_KEY="$gasfree_api_key" GASFREE_SECRET="$gasfree_api_secret" node -e '
console.log(JSON.stringify({ gasfree_api_key: process.env.GASFREE_KEY, gasfree_api_secret: process.env.GASFREE_SECRET }));
')
            node_json_write "$x402_config" "$json_content"
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
}

configure_skill() {
    local skill_id="$1"

    case "$skill_id" in
        "sunperp")
            echo ""
            echo -e "${WARN}sunperp depends on TRON_PRIVATE_KEY.${NC}"
            echo -e "${MUTED}Please ensure TRON_PRIVATE_KEY is configured before using sunperp.${NC}"
            echo ""
            ;;
        "x402-payment")
            configure_x402_gasfree
            ;;
        "recharge-skill")
            configure_bankofai_api_key
            ;;
        "tronscan-skill")
            configure_tronscan_api_key
            ;;
    esac
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
    "mcp-server-tron||Interact with TRON blockchain (wallets, transactions, smart contracts)."
    "bnbchain-mcp||BNB Chain official MCP (BSC, opBNB, Ethereum, Greenfield)."
    "bankofai-recharge||BANK OF AI recharge MCP (remote recharge tools)."
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
                 echo -e "${MUTED}Adding MCP server...${NC}"

                 if ! npx -y add-mcp -a mcporter -n mcp-server-tron -g -y "@bankofai/mcp-server-tron@1.1.7" 2>&1; then
                     echo -e "${ERROR}✗ Failed to add mcp-server-tron via npx add-mcp${NC}"
                     continue
                 fi

                 ;;

            "bnbchain-mcp")
                 echo -e "${WARN}bnbchain-mcp currently does not support AgentWallet.${NC}"
                 echo -e "${WARN}This server still uses PRIVATE_KEY configuration.${NC}"
                 echo ""
                 echo -e "${WARN}⚠ Your PRIVATE_KEY will be stored in plaintext in: ${INFO}$MCP_CONFIG_FILE${NC}"
                 echo -e "${WARN}  File permissions are set to 600 (owner-only), but take care with backups.${NC}"
                 echo ""

                 ask_input "Enter BNB Chain PRIVATE_KEY" BNB_KEY 1 "Your BNB Chain wallet private key (with or without 0x prefix). Required for signing transactions."
                 ask_input "Enter LOG_LEVEL" BNB_LOG_LEVEL 0 "Log level: DEBUG, INFO, WARN, ERROR (default: INFO)"

                 echo -e "${MUTED}Adding MCP server...${NC}"

                 if ! npx -y add-mcp -a mcporter -n bnbchain-mcp -g -y "@bnb-chain/mcp@latest" 2>&1; then
                     echo -e "${ERROR}✗ Failed to add bnbchain-mcp via npx add-mcp${NC}"
                     continue
                 fi

                 # Ensure private key has 0x prefix
                 if [ -n "$BNB_KEY" ]; then
                     if [[ ! "$BNB_KEY" =~ ^0x ]]; then
                         BNB_KEY="0x${BNB_KEY}"
                         echo -e "${INFO}Added 0x prefix to private key${NC}"
                     fi
                 fi

                 # Inject env vars into mcporter.json
                 if [ -n "${BNB_KEY:-}" ] || [ -n "${BNB_LOG_LEVEL:-}" ]; then
                     env_json=$(BNB_PRIVATE_KEY="${BNB_KEY:-}" BNB_LOG="${BNB_LOG_LEVEL:-INFO}" node -e '
const d = {};
if (process.env.BNB_PRIVATE_KEY) d.PRIVATE_KEY = process.env.BNB_PRIVATE_KEY;
d.LOG_LEVEL = process.env.BNB_LOG;
console.log(JSON.stringify(d));
')
                     node_json_merge "bnbchain-mcp" "$env_json" "$MCP_CONFIG_FILE"
                 fi
                 ;;

            "bankofai-recharge")
                 if ! npx -y add-mcp -a mcporter -n bankofai-recharge -g -t http -y "https://recharge.bankofai.io/mcp" 2>&1; then
                     echo -e "${ERROR}✗ Failed to add bankofai-recharge via npx add-mcp${NC}"
                     continue
                 fi
                 ;;
        esac

        echo -e "${SUCCESS}✓ Configuration saved for $SERVER_ID.${NC}"
    done

    # Secure mcporter.json — it may contain PRIVATE_KEY in plaintext
    chmod 600 "$MCP_CONFIG_FILE"
fi

# --- Step 2: Skills Installation ---

echo ""
echo -e "${BOLD}Step 2: Skills Installation${NC}"
echo ""

# Select install scope
echo -e "${BOLD}Select skills installation scope:${NC}"
echo -e "  ${INFO}1)${NC} User-level (global) ${SUCCESS}[Recommended]${NC}"
echo -e "     ${MUTED}Available to all OpenClaw workspaces${NC}"
echo -e "  ${INFO}2)${NC} Workspace-level (project)"
echo -e "     ${MUTED}Only available in current workspace${NC}"
echo ""
echo -ne "${INFO}?${NC} Enter choice ${MUTED}(1-2, default: 1)${NC}: "

read -r scope_choice <&3
scope_choice=${scope_choice:-1}

if [ "$scope_choice" = "1" ]; then
    SKILLS_GLOBAL_FLAG="-g"
    echo -e "${MUTED}→ Installing globally (user-level)${NC}"
else
    SKILLS_GLOBAL_FLAG=""
    echo -e "${MUTED}→ Installing to workspace${NC}"
fi
echo ""

# Snapshot installed skills before
BEFORE_SKILLS=$(npx -y skills@1.4.6 list $SKILLS_GLOBAL_FLAG -a openclaw --json 2>/dev/null || echo "[]")

# Run interactive skills add — user picks skills via built-in multi-select
echo -e "${INFO}Select skills to install in the interactive prompt below:${NC}"
echo ""
npx -y skills@1.4.6 add "$SKILLS_REPO" -a openclaw $SKILLS_GLOBAL_FLAG <&3 2>&1 || true
echo ""

# Snapshot after and find newly installed skills
AFTER_SKILLS=$(npx -y skills@1.4.6 list $SKILLS_GLOBAL_FLAG -a openclaw --json 2>/dev/null || echo "[]")
INSTALLED_SKILLS=()
while IFS= read -r skill_id; do
    [ -z "$skill_id" ] && continue
    INSTALLED_SKILLS+=("$skill_id")
done < <(BEFORE="$BEFORE_SKILLS" AFTER="$AFTER_SKILLS" node -e '
const before = new Set(JSON.parse(process.env.BEFORE).map(s => s.name || s.skill || s));
const after = JSON.parse(process.env.AFTER).map(s => s.name || s.skill || s);
after.filter(s => !before.has(s)).forEach(s => console.log(s));
')

if [ ${#INSTALLED_SKILLS[@]} -gt 0 ]; then
    echo -e "${SUCCESS}✓ Installed ${#INSTALLED_SKILLS[@]} skill(s)${NC}"
    echo ""

    # Run post-install configuration for each new skill
    for skill_id in "${INSTALLED_SKILLS[@]}"; do
        configure_skill "$skill_id"
    done
else
    echo -e "${MUTED}No new skills were installed.${NC}"
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
    echo -e "  ${MUTED}  File permissions: 600 (owner read/write only)${NC}"
    echo ""
fi

if [ ${#INSTALLED_SKILLS[@]} -gt 0 ]; then
    echo -e "${SUCCESS}✓${NC} ${BOLD}Installed skills:${NC}"
    for skill in "${INSTALLED_SKILLS[@]}"; do
        echo -e "  ${SUCCESS}•${NC} ${INFO}$skill${NC}"
    done
    echo -e "  ${MUTED}Verify with: ${INFO}npx skills list ${SKILLS_GLOBAL_FLAG}${NC}"
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
