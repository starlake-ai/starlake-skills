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
CHANNEL=""
PIN=""

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
  --channel CHANNEL       Switch the repo before installing: 'stable' (newest
                          vX.Y.Z tag) or 'latest' (main branch). Without this
                          flag the repo's git state is never touched.
  --pin TAG               Switch the repo to an exact tag (e.g. v1.2.0)
  --version               Print the installed version and exit
  --help                  Show this help message

Examples:
  $(basename "$0")                          # Install globally for all platforms
  $(basename "$0") --platforms claude       # Install globally for Claude Code only
  $(basename "$0") --local                  # Install into current project
  $(basename "$0") --update                 # Re-install (removes old links first)
  $(basename "$0") --update --channel stable # Update to the newest tagged release
  $(basename "$0") --pin v1.2.0             # Install an exact release
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
    --channel)   CHANNEL="$2"; shift 2 ;;
    --pin)       PIN="$2"; shift 2 ;;
    --version)   ACTION="version"; shift ;;
    --help)      usage ;;
    *)           echo "Unknown option: $1"; usage ;;
  esac
done

# ── Validation ─────────────────────────────────────────────────────────
if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "Error: .agents/ directory not found at $AGENTS_DIR"
  exit 1
fi

if [[ -n "$CHANNEL" && "$CHANNEL" != "stable" && "$CHANNEL" != "latest" ]]; then
  echo "Error: --channel must be 'stable' or 'latest' (got '$CHANNEL')"
  exit 1
fi

if [[ -n "$CHANNEL" && -n "$PIN" ]]; then
  echo "Error: --channel and --pin are mutually exclusive"
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

repo_version() {
  if git -C "$REPO_DIR" describe --tags --always 2>/dev/null; then
    return
  fi
  # Tarball installs (install-remote.sh) have no .git but carry a stamped VERSION file.
  if [[ -f "$REPO_DIR/VERSION" ]]; then
    cat "$REPO_DIR/VERSION"
    return
  fi
  echo "unknown"
}

# Switch the repo to the requested channel or pinned tag.
# Only called when --channel or --pin was passed explicitly.
switch_version() {
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for --channel / --pin"
    exit 1
  fi
  if ! git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: $REPO_DIR is not a git repository"
    echo "(release-tarball install? switch versions with install-remote.sh --pin instead)"
    exit 1
  fi

  if ! git -C "$REPO_DIR" fetch --tags --quiet 2>/dev/null; then
    echo "  Warning: could not fetch from remote, using local refs"
    ((WARNINGS++)) || true
  fi

  local ref=""
  if [[ -n "$PIN" ]]; then
    ref="$PIN"
  elif [[ "$CHANNEL" == "stable" ]]; then
    ref="$(git -C "$REPO_DIR" tag --list 'v[0-9]*' --sort=-v:refname | head -n 1)"
    if [[ -z "$ref" ]]; then
      echo "Error: no vX.Y.Z tags found; the stable channel requires at least one release tag"
      exit 1
    fi
  else # latest
    ref="main"
  fi

  echo "Switching repo to $ref"
  if ! git -C "$REPO_DIR" checkout --quiet "$ref"; then
    echo "Error: could not check out '$ref' (uncommitted changes in $REPO_DIR?)"
    exit 1
  fi
  if [[ "$ref" == "main" ]]; then
    git -C "$REPO_DIR" pull --ff-only --quiet 2>/dev/null || {
      echo "  Warning: could not fast-forward main, using local state"
      ((WARNINGS++)) || true
    }
  fi
  echo "Installed version: $(repo_version)"
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

if [[ "$ACTION" == "version" ]]; then
  repo_version
  exit 0
fi

# A channel/pin switch may add or remove skill folders, so re-link from scratch.
if [[ ( -n "$CHANNEL" || -n "$PIN" ) && "$ACTION" != "uninstall" ]]; then
  switch_version
  [[ "$ACTION" == "install" ]] && ACTION="update"
fi

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
