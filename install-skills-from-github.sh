#!/bin/bash
set -euo pipefail

# Skills-Tron Installer for OpenClaw Extension
# Installs TRON skills from GitHub repository

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
GITHUB_REPO="https://github.com/bankofai/skills-tron.git"
OPENCLAW_USER_SKILLS="$HOME/.openclaw/skills"
OPENCLAW_WORKSPACE_SKILLS=".openclaw/skills"
INSTALLED_SKILLS=()
TEMP_DIR=""

# Ensure we have a TTY for user interaction
if [ -t 0 ]; then
    exec 3<&0
elif [ -e /dev/tty ]; then
    exec 3</dev/tty
else
    exec 3<&0
fi

# --- Cleanup ---
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

# --- Taglines ---
TAGLINES=(
    "Teaching OpenClaw to trade like a TRON native."
    "DeFi skills: Because agents deserve low fees too."
    "From zero to DEX trading in one script."
    "Installing SunSwap superpowers for your AI agent."
    "TRON skills: Low fees, high speeds, zero excuses."
    "Your AI agent's gateway to TRON DeFi."
)

pick_tagline() {
    local count=${#TAGLINES[@]}
    local idx=$((RANDOM % count))
    echo "${TAGLINES[$idx]}"
}

TAGLINE=$(pick_tagline)

# --- Helper Functions ---

check_env() {
    if ! command -v git &> /dev/null; then
        echo -e "${ERROR}Error: git is not installed.${NC}"
        exit 1
    fi
}

clone_repo() {
    echo -e "${INFO}Cloning skills-tron repository...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    if ! git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR" 2>/dev/null; then
        echo -e "${ERROR}Error: Failed to clone repository from $GITHUB_REPO${NC}"
        exit 1
    fi
    
    echo -e "${SUCCESS}✓ Repository cloned${NC}"
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
            "") # Enter key
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
                        if [ $current -lt 0 ]; then
                            current=$((${#options[@]} - 1))
                        fi
                        ;;
                    "[B") # Down Arrow
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

select_install_target() {
    echo -e "${BOLD}Select installation location:${NC}"
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

copy_skill() {
    local skill_id="$1"
    local target_dir="$2"
    
    echo -e "${INFO}Installing ${BOLD}$skill_id${NC}${INFO}...${NC}"
    
    # Check if skill exists in cloned repo
    if [ ! -d "$TEMP_DIR/$skill_id" ]; then
        echo -e "${ERROR}✗ Skill $skill_id not found in repository${NC}"
        return 1
    fi
    
    # Check if SKILL.md exists
    if [ ! -f "$TEMP_DIR/$skill_id/SKILL.md" ]; then
        echo -e "${ERROR}✗ $skill_id/SKILL.md not found${NC}"
        return 1
    fi
    
    # Check if already exists
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
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Copy skill
    cp -r "$TEMP_DIR/$skill_id" "$target_dir/"
    
    # Verify installation
    if [ -f "$target_dir/$skill_id/SKILL.md" ]; then
        echo -e "${SUCCESS}✓ $skill_id installed successfully${NC}"
        INSTALLED_SKILLS+=("$skill_id")
        return 0
    else
        echo -e "${ERROR}✗ Installation failed${NC}"
        return 1
    fi
}

show_summary() {
    echo ""
    echo -e "${ACCENT}${BOLD}═══════════════════════════════════════${NC}"
    echo -e "${ACCENT}${BOLD}  Installation Complete!${NC}"
    echo -e "${ACCENT}${BOLD}═══════════════════════════════════════${NC}"
    echo ""
    
    if [ ${#INSTALLED_SKILLS[@]} -gt 0 ]; then
        echo -e "${SUCCESS}✓${NC} ${BOLD}Installed skills:${NC}"
        for skill in "${INSTALLED_SKILLS[@]}"; do
            echo -e "  ${SUCCESS}•${NC} ${INFO}$skill${NC}"
        done
        echo ""
    else
        echo -e "${WARN}No skills were installed.${NC}"
        echo ""
        return
    fi
    
    echo -e "${INFO}Installation path:${NC} ${BOLD}$TARGET_DIR${NC}"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  ${INFO}1.${NC} ${BOLD}Restart OpenClaw${NC} to load new skills"
    echo -e "     ${MUTED}• Close OpenClaw completely${NC}"
    echo -e "     ${MUTED}• Reopen OpenClaw${NC}"
    echo ""
    echo -e "  ${INFO}2.${NC} ${BOLD}Test the skills:${NC}"
    
    for skill in "${INSTALLED_SKILLS[@]}"; do
        case "$skill" in
            "sunswap")
                echo -e "     ${MUTED}\"Read the sunswap skill and help me swap 100 USDT to TRX\"${NC}"
                ;;
            "x402_tron_payment")
                echo -e "     ${MUTED}\"Read the x402_tron_payment skill and explain how it works\"${NC}"
                ;;
            "x402_tron_payment_demo")
                echo -e "     ${MUTED}\"Read the x402_tron_payment_demo skill and run the demo\"${NC}"
                ;;
        esac
    done
    
    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo -e "  ${MUTED}Repository: https://github.com/bankofai/skills-tron${NC}"
    echo -e "  ${MUTED}Each skill includes detailed SKILL.md documentation${NC}"
    echo ""
}

# --- Main Logic ---

echo -e "${ACCENT}${BOLD}"
echo "  🦞 Skills-Tron Installer (by BankofAI)"
echo -e "${NC}${ACCENT_DIM}  $TAGLINE${NC}"
echo ""

# Step 1: Check environment
check_env

# Step 2: Clone repository
clone_repo

# Step 3: Discover available skills
SKILL_OPTIONS=()
SKILL_IDS=()

# Scan for skills in the cloned repo
for dir in "$TEMP_DIR"/*; do
    if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
        skill_name=$(basename "$dir")
        
        # Skip installer directory
        if [ "$skill_name" = "installer" ]; then
            continue
        fi
        
        # Read first line of SKILL.md as description
        description=$(head -n 1 "$dir/SKILL.md" | sed 's/^#* *//' | sed 's/^---$//')
        
        # If description is empty or just dashes, try to get from frontmatter
        if [ -z "$description" ] || [ "$description" = "---" ]; then
            description=$(grep "^description:" "$dir/SKILL.md" 2>/dev/null | head -n 1 | sed 's/^description: *//' || echo "")
        fi
        
        # Fallback to skill name if still empty
        if [ -z "$description" ]; then
            description="TRON skill"
        fi
        
        SKILL_IDS+=("$skill_name")
        SKILL_OPTIONS+=("$skill_name - $description")
    fi
done

if [ ${#SKILL_OPTIONS[@]} -eq 0 ]; then
    echo -e "${ERROR}Error: No skills found in repository${NC}"
    exit 1
fi

# Step 4: Select skills to install
echo ""
SELECTED_INDICES=()
multiselect "Select skills to install:" SELECTED_INDICES "${SKILL_OPTIONS[@]}"

if [ ${#SELECTED_INDICES[@]} -eq 0 ]; then
    echo -e "${WARN}No skills selected. Exiting.${NC}"
    exit 0
fi

echo ""

# Step 5: Select installation target
select_install_target

# Step 6: Install selected skills
echo -e "${BOLD}Installing skills...${NC}"
echo ""

for idx in "${SELECTED_INDICES[@]}"; do
    skill_id="${SKILL_IDS[$idx]}"
    copy_skill "$skill_id" "$TARGET_DIR"
done

# Step 7: Show summary
show_summary
