#!/usr/bin/env bash
# Sync this plugin's skill files (src/skills/*) into the installed plugin
# directory under macOS's Claude Desktop application support tree.
#
# Requirements:
#   - macOS only (looks under "$HOME/Library/Application Support/Claude").
#   - bash 4+ (uses `mapfile`). Stock /bin/bash on macOS is 3.2 — install via
#     `brew install bash` and make sure it resolves first in PATH.
#
# Usage:
#   ./sync-skills.sh                 # sync every skill under src/skills/
#   ./sync-skills.sh <skill-name>    # sync only the named skill directory
#
# Or via the dev.yaml task runner:
#   task sync                        # all skills
#   task sync -- <skill-name>        # one skill
#
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "Error: bash 4+ is required (this is bash $BASH_VERSION)." >&2
  echo "Install via: brew install bash" >&2
  exit 1
fi

SELF="${BASH_SOURCE[0]:-$0}"
PLUGIN_SRC="$(cd "$(dirname "$SELF")" && pwd)/src/skills"

usage() {
  echo "Usage: $0 [skill-name]   (default: all)" >&2
  echo "  skill-name: directory name under $PLUGIN_SRC" >&2
  echo "  (no arg):   sync every skill under $PLUGIN_SRC" >&2
  exit 1
}

if [[ $# -gt 1 ]]; then
  usage
fi

TARGET="${1:-all}"

if [[ ! -d "$PLUGIN_SRC" ]]; then
  echo "Error: plugin source dir not found: $PLUGIN_SRC" >&2
  exit 1
fi

BASE_DIR="$HOME/Library/Application Support/Claude"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: Claude Desktop support dir not found: $BASE_DIR" >&2
  echo "This script is macOS-only and requires Claude Desktop to be installed." >&2
  exit 1
fi

# Discover every installed plugin's "skills/" directory, then keep only the
# ones that look like a noibu plugin install (i.e. already contain at least
# one of the skills we ship in this repo). This avoids leaking our skills
# into unrelated plugins that happen to live under the same base dir.
mapfile -d '' CANDIDATE_DIRS < <(find "$BASE_DIR" -type d -regex '.*/plugin_[^/]*/skills' -print0)

SOURCE_SKILLS=()
for skill_path in "$PLUGIN_SRC"/*/; do
  SOURCE_SKILLS+=("$(basename "$skill_path")")
done

PLUGIN_SKILLS_DIRS=()
for dir in "${CANDIDATE_DIRS[@]}"; do
  for name in "${SOURCE_SKILLS[@]}"; do
    if [[ -d "$dir/$name" ]]; then
      PLUGIN_SKILLS_DIRS+=("$dir")
      break
    fi
  done
done

if [[ ${#PLUGIN_SKILLS_DIRS[@]} -eq 0 ]]; then
  echo "Error: no installed noibu plugin skills/ directory found under $BASE_DIR" >&2
  echo "(install the plugin at least once so one of: ${SOURCE_SKILLS[*]} exists)" >&2
  exit 1
fi

sync_skill() {
  local name="$1"
  local src="$PLUGIN_SRC/$name"

  if [[ ! -d "$src" ]]; then
    echo "Error: skill not found in source: $src" >&2
    return 1
  fi

  for skills_dir in "${PLUGIN_SKILLS_DIRS[@]}"; do
    local target="$skills_dir/$name"
    mkdir -p "$target"
    rsync -a --delete "$src/" "$target/"
    echo "Updated: $target"
  done
}

if [[ "$TARGET" == "all" ]]; then
  for skill_path in "$PLUGIN_SRC"/*/; do
    sync_skill "$(basename "$skill_path")"
  done
else
  sync_skill "$TARGET"
fi
