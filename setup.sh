#!/usr/bin/env zsh
# setup.sh — run after cloning or whenever scripts change
# Usage: ./setup.sh

set -euo pipefail

REPO_DIR="${0:A:h}"   # absolute path to the repo, regardless of where you call it from
SCRIPTS_DIR="$REPO_DIR/scripts"
BIN_DIR="$HOME/.local/bin"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'

echo "\n${CYAN}═══ DotFiles setup ═════════════════════════════════${RESET}\n"

# ── Make all scripts executable ──────────────────────────────────────────────
chmod +x "$SCRIPTS_DIR"/*
echo "  ${GREEN}✔${RESET}  Scripts marked executable"

# ── Clean up stale symlinks ──────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
cleaned=0

for link in "$BIN_DIR"/*; do
  [[ ! -L "$link" ]] && continue                        # skip non-symlinks
  local target="$(readlink "$link")"
  [[ "$target" != "$REPO_DIR"/* ]] && continue             # skip links not managed by us
  if [[ ! -e "$link" ]]; then                            # dangling — target was deleted
    rm "$link"
    echo "  ${YELLOW}✔${RESET}  Removed stale symlink: $(basename "$link")"
    cleaned=$((cleaned + 1))
  fi
done

[[ $cleaned -eq 0 ]] && echo "  ${GREEN}✔${RESET}  No stale symlinks found"

# ── Symlink scripts to ~/.local/bin ──────────────────────────────────────────
for script in "$SCRIPTS_DIR"/*; do
  name="$(basename "$script")"
  target="$BIN_DIR/$name"
  if [[ -L "$target" && -e "$target" ]]; then
    echo "  ${GREEN}✔${RESET}  $name already symlinked, skipping"
  else
    [[ -L "$target" ]] && rm "$target"   # remove dangling symlink before replacing
    ln -s "$script" "$target"
    echo "  ${GREEN}✔${RESET}  Symlinked $name → $target"
  fi
done

echo "\n  ${GREEN}Done.${RESET}"
