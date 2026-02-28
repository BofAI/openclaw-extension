#!/bin/bash
set -euo pipefail

# Install latest AINFT PLAYBOOK into OpenClaw skill directory.
# Default mode: pull from remote GitHub branch/path.

if [[ -n "${BASH_SOURCE:-}" && -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Support `curl ... | bash` where BASH_SOURCE may be unavailable.
  SCRIPT_DIR="$(pwd)"
fi
TARGET_ROOT="${OPENCLAW_SKILLS_DIR:-$HOME/.openclaw/skills}"
TARGET_FILE="$TARGET_ROOT/ainft-skill/PLAYBOOK.md"
BACKUP_DIR="$HOME/.openclaw/.backup_playbook"
TMP_DIR=""
WORKSPACE_SOURCE_DIR="$SCRIPT_DIR/workspace"
WORKSPACE_TARGET_DIR="${OPENCLAW_WORKSPACE_DIR:-}"
PERSONA_FILES=("SOUL.md" "AGENTS.md" "IDENTITY.md" "USER.md")
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

# Remote defaults
REPO="https://github.com/bankofai/skills.git"
REF="dev/playbook"
SKILL_PATH="ainft-skill/PLAYBOOK.md"
MODE="remote"
SOURCE_FILE=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  ./install_playbook.sh [--target-dir <path>]
  ./install_playbook.sh --source <local-path> [--target-dir <path>]
  ./install_playbook.sh [--repo <git-url>] [--ref <branch>] [--path <skill-playbook-path>] [--workspace-dir <path>]

Options:
  --source      Use local playbook file instead of remote.
  --repo        Remote git repo. Default: https://github.com/bankofai/skills.git
  --ref         Remote branch/tag/ref. Default: dev/playbook
  --path        Playbook path in repo. Default: ainft-skill/PLAYBOOK.md
  --target-dir  OpenClaw skills root. Default: ~/.openclaw/skills
  --workspace-dir  OpenClaw workspace dir for persona sync (override auto-detect)
  -h, --help    Show this help
EOF
}

detect_workspace_dir() {
  # 1) explicit override from env/arg
  if [[ -n "$WORKSPACE_TARGET_DIR" ]]; then
    echo "$WORKSPACE_TARGET_DIR"
    return 0
  fi

  # 2) OpenClaw configured workspace
  if [[ -f "$OPENCLAW_CONFIG" ]] && command -v python3 >/dev/null 2>&1; then
    local configured=""
    configured="$(python3 - <<'PY' "$OPENCLAW_CONFIG"
import json, sys
path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    ws = data.get("agents", {}).get("defaults", {}).get("workspace", "")
    if isinstance(ws, str):
        print(ws)
except Exception:
    pass
PY
)"
    if [[ -n "$configured" ]]; then
      echo "$configured"
      return 0
    fi
  fi

  # 3) fallback paths
  if [[ -d "$HOME/.openclaw/workspace-web3" ]]; then
    echo "$HOME/.openclaw/workspace-web3"
    return 0
  fi
  if [[ -d "$HOME/.openclaw/workspace" ]]; then
    echo "$HOME/.openclaw/workspace"
    return 0
  fi

  # 4) last resort
  echo "$HOME/.openclaw/workspace-web3"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      MODE="local"
      SOURCE_FILE="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --path)
      SKILL_PATH="${2:-}"
      shift 2
      ;;
    --target-dir)
      TARGET_ROOT="${2:-}"
      TARGET_FILE="$TARGET_ROOT/ainft-skill/PLAYBOOK.md"
      shift 2
      ;;
    --workspace-dir)
      WORKSPACE_TARGET_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$MODE" == "remote" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for remote installation." >&2
    exit 1
  fi

  TMP_DIR="$(mktemp -d)"
  CLONE_DIR="$TMP_DIR/repo"
  git clone --depth 1 --branch "$REF" "$REPO" "$CLONE_DIR" >/dev/null 2>&1 || {
    echo "Error: failed to clone $REPO (ref: $REF)." >&2
    exit 1
  }
  SOURCE_FILE="$CLONE_DIR/$SKILL_PATH"
  # Prefer local workspace templates if present; otherwise use remote repo workspace.
  if [[ ! -d "$WORKSPACE_SOURCE_DIR" ]]; then
    WORKSPACE_SOURCE_DIR="$CLONE_DIR/workspace"
  fi
else
  if [[ -z "$SOURCE_FILE" ]]; then
    echo "Error: --source requires a file path." >&2
    exit 1
  fi
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: source playbook not found: $SOURCE_FILE" >&2
  exit 1
fi

WORKSPACE_TARGET_DIR="$(detect_workspace_dir)"

mkdir -p "$TARGET_ROOT/ainft-skill"
mkdir -p "$BACKUP_DIR"

if [[ -f "$TARGET_FILE" ]]; then
  ts="$(date +%Y%m%d_%H%M%S)"
  backup_file="$BACKUP_DIR/PLAYBOOK.$ts.md"
  cp "$TARGET_FILE" "$backup_file"
  echo "Backed up existing playbook -> $backup_file"
fi

cp "$SOURCE_FILE" "$TARGET_FILE"

if ! grep -q "AINFT 存活剧本" "$TARGET_FILE"; then
  echo "Error: installed file failed validation (missing expected header)." >&2
  exit 1
fi

echo "Playbook installed successfully:"
echo "  source: $SOURCE_FILE"
echo "  target: $TARGET_FILE"

mkdir -p "$WORKSPACE_TARGET_DIR"
persona_synced=()
for f in "${PERSONA_FILES[@]}"; do
  src="$WORKSPACE_SOURCE_DIR/$f"
  dst="$WORKSPACE_TARGET_DIR/$f"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    persona_synced+=("$f")
  fi
done

if [[ ${#persona_synced[@]} -gt 0 ]]; then
  echo "Persona files synced to workspace:"
  echo "  workspace: $WORKSPACE_TARGET_DIR"
  for f in "${persona_synced[@]}"; do
    echo "  - $f"
  done
else
  echo "Warning: no persona files found under $WORKSPACE_SOURCE_DIR" >&2
fi

echo ""
echo "Next: restart/reload OpenClaw session and test survival flow."
