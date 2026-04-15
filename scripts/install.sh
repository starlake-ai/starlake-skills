#!/usr/bin/env bash
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_DIR="$REPO_DIR/.agents"
ALL_PLATFORMS="claude,copilot,gemini"

# ── Defaults ───────────────────────────────────────────────────────────
MODE="global"
ACTION="install"
PLATFORMS="$ALL_PLATFORMS"

# ── Usage ──────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install starlake-skills by symlinking into AI coding assistant directories.

Options:
  --global                Install to ~/.<platform>/skills/ (default)
  --local                 Install to ./.<platform>/skills/ in current directory
  --update                Remove existing starlake symlinks, then re-install
  --uninstall             Remove all starlake-skills symlinks
  --platforms PLATFORMS   Comma-separated: claude,copilot,gemini (default: all)
  --help                  Show this help message

Examples:
  $(basename "$0")                          # Install globally for all platforms
  $(basename "$0") --platforms claude       # Install globally for Claude Code only
  $(basename "$0") --local                  # Install into current project
  $(basename "$0") --update                 # Re-install (removes old links first)
  $(basename "$0") --uninstall              # Remove all starlake symlinks
EOF
  exit 0
}

# ── Argument parsing ───────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)    MODE="global"; shift ;;
    --local)     MODE="local"; shift ;;
    --update)    ACTION="update"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    --help)      usage ;;
    *)           echo "Unknown option: $1"; usage ;;
  esac
done

# ── Validation ─────────────────────────────────────────────────────────
if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "Error: .agents/ directory not found at $AGENTS_DIR"
  exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────────
INSTALLED=0
SKIPPED=0
WARNINGS=0
REMOVED=0
ERRORS=0

resolve_base_dir() {
  local platform="$1"
  if [[ "$MODE" == "global" ]]; then
    echo "$HOME/.$platform"
  else
    echo ".$platform"
  fi
}

# Check if a symlink points into our repo
is_starlake_link() {
  local link="$1"
  if [[ -L "$link" ]]; then
    local target
    target="$(readlink "$link")"
    # Resolve to absolute if relative
    if [[ "$target" != /* ]]; then
      target="$(cd "$(dirname "$link")" && cd "$(dirname "$target")" && pwd)/$(basename "$target")"
    fi
    [[ "$target" == "$REPO_DIR"* ]]
  else
    return 1
  fi
}

create_symlink() {
  local source="$1"
  local target="$2"
  local name
  name="$(basename "$target")"

  if [[ -L "$target" ]]; then
    if is_starlake_link "$target"; then
      ((SKIPPED++)) || true
      return
    else
      echo "  Warning: $target is a symlink to a different source, skipping"
      ((WARNINGS++)) || true
      return
    fi
  elif [[ -e "$target" ]]; then
    echo "  Warning: $target exists and is not a symlink, skipping"
    ((WARNINGS++)) || true
    return
  fi

  ln -s "$source" "$target"
  ((INSTALLED++)) || true
}

remove_starlake_links() {
  local dir="$1"

  # Remove skill symlinks
  if [[ -d "$dir/skills" ]]; then
    for entry in "$dir/skills/"*; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      if is_starlake_link "$entry"; then
        rm "$entry"
        ((REMOVED++)) || true
      fi
    done
  fi

  # Remove starflow symlink
  if [[ -L "$dir/starflow" ]] && is_starlake_link "$dir/starflow"; then
    rm "$dir/starflow"
    ((REMOVED++)) || true
  fi
}

install_platform() {
  local platform="$1"
  local base_dir
  base_dir="$(resolve_base_dir "$platform")"
  local skills_dir="$base_dir/skills"

  echo "Installing for $platform -> $base_dir"

  if ! mkdir -p "$skills_dir" 2>/dev/null; then
    echo "  Error: cannot create $skills_dir"
    ((ERRORS++)) || true
    return
  fi

  # Symlink core skills
  for skill_dir in "$AGENTS_DIR/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    create_symlink "$skill_dir" "$skills_dir/$name"
  done

  # Symlink starflow skills
  for skill_dir in "$AGENTS_DIR/starflow/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    create_symlink "$skill_dir" "$skills_dir/$name"
  done

  # Symlink starflow directory (config + templates)
  create_symlink "$AGENTS_DIR/starflow" "$base_dir/starflow"
}

uninstall_platform() {
  local platform="$1"
  local base_dir
  base_dir="$(resolve_base_dir "$platform")"

  echo "Uninstalling for $platform <- $base_dir"
  remove_starlake_links "$base_dir"
}

# ── Main ───────────────────────────────────────────────────────────────
IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"

case "$ACTION" in
  install)
    for p in "${PLATFORM_LIST[@]}"; do
      install_platform "$p"
    done
    echo ""
    echo "Done: $INSTALLED installed, $SKIPPED already present, $WARNINGS warnings, $ERRORS errors"
    ;;
  update)
    for p in "${PLATFORM_LIST[@]}"; do
      uninstall_platform "$p"
    done
    for p in "${PLATFORM_LIST[@]}"; do
      install_platform "$p"
    done
    echo ""
    echo "Done: $REMOVED removed, $INSTALLED installed, $WARNINGS warnings, $ERRORS errors"
    ;;
  uninstall)
    for p in "${PLATFORM_LIST[@]}"; do
      uninstall_platform "$p"
    done
    echo ""
    echo "Done: $REMOVED symlinks removed"
    ;;
esac

[[ "$ERRORS" -eq 0 ]] || exit 1
