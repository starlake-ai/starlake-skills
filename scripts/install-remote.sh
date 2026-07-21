#!/usr/bin/env bash
set -euo pipefail

# Bootstrap installer: downloads a starlake-skills release tarball from GitHub
# Releases into an install directory, then runs the bundled install.sh to
# symlink the skills. No git or Node required; only curl and tar.
#
# Typical use (bash required: the script uses arrays):
#   curl -fsSL https://raw.githubusercontent.com/starlake-ai/starlake-skills/main/scripts/install-remote.sh | bash
#
# Env overrides (mirrors, forks, enterprise):
#   STARLAKE_SKILLS_REPO      owner/repo slug (default: starlake-ai/starlake-skills)
#   STARLAKE_SKILLS_BASE_URL  release-asset base URL
#   STARLAKE_SKILLS_API_URL   latest-release API URL

REPO_SLUG="${STARLAKE_SKILLS_REPO:-starlake-ai/starlake-skills}"
BASE_URL="${STARLAKE_SKILLS_BASE_URL:-https://github.com/$REPO_SLUG/releases/download}"
API_URL="${STARLAKE_SKILLS_API_URL:-https://api.github.com/repos/$REPO_SLUG/releases/latest}"
INSTALL_DIR="${STARLAKE_SKILLS_DIR:-$HOME/.starlake-skills}"
PIN=""
PASSTHRU=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [-- installer options]

Download a starlake-skills release and install it.

Options:
  --pin TAG    Install an exact release (e.g. v1.2.0). Default: latest release.
  --dir DIR    Install directory (default: ~/.starlake-skills)
  --help       Show this help message

Any other option is passed through to install.sh (e.g. --platforms claude,
--local, --uninstall). --uninstall skips the download and runs the already
installed copy's uninstaller.
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pin)  PIN="$2"; shift 2 ;;
    --dir)  INSTALL_DIR="$2"; shift 2 ;;
    --help) usage ;;
    --)     shift; PASSTHRU+=("$@"); break ;;
    *)      PASSTHRU+=("$1"); shift ;;
  esac
done

run_installer() {
  bash "$INSTALL_DIR/scripts/install.sh" "$@" ${PASSTHRU[@]+"${PASSTHRU[@]}"}
}

# Uninstall never needs a download.
for arg in ${PASSTHRU[@]+"${PASSTHRU[@]}"}; do
  if [[ "$arg" == "--uninstall" ]]; then
    if [[ ! -f "$INSTALL_DIR/scripts/install.sh" ]]; then
      echo "Error: no installation found at $INSTALL_DIR"
      exit 1
    fi
    bash "$INSTALL_DIR/scripts/install.sh" ${PASSTHRU[@]+"${PASSTHRU[@]}"}
    exit $?
  fi
done

# Never clobber a git clone: that workflow updates via git, not tarballs.
if [[ -e "$INSTALL_DIR/.git" ]]; then
  echo "Error: $INSTALL_DIR is a git clone. Update it with 'git pull' +"
  echo "'scripts/install.sh --update' (or --channel/--pin), not with this script."
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "Error: curl is required"; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "Error: tar is required"; exit 1; }

# Resolve the tag to install
TAG="$PIN"
if [[ -z "$TAG" ]]; then
  TAG="$(curl -fsSL "$API_URL" | grep -o '"tag_name" *: *"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)"
  if [[ -z "$TAG" ]]; then
    echo "Error: could not resolve the latest release from $API_URL"
    echo "(no releases published yet? pass --pin vX.Y.Z, or install via git clone)"
    exit 1
  fi
fi

ASSET="starlake-skills-$TAG.tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading $ASSET ($BASE_URL/$TAG/$ASSET)"
curl -fsSL -o "$TMP_DIR/$ASSET" "$BASE_URL/$TAG/$ASSET"
tar -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR"

if [[ ! -f "$TMP_DIR/starlake-skills/scripts/install.sh" ]]; then
  echo "Error: unexpected archive layout in $ASSET"
  exit 1
fi

# Swap in the new version, then re-link from scratch (skills may have changed).
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$TMP_DIR/starlake-skills" "$INSTALL_DIR"

echo "Installed $TAG to $INSTALL_DIR"
run_installer --update
