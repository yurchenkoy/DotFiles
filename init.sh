#!/usr/bin/env zsh
# init.sh — run once after cloning the repo on a new machine
# Usage: ./init.sh

set -euo pipefail

REPO_DIR="${0:A:h}"   # absolute path to the repo, regardless of where you call it from
BIN_DIR="$HOME/.local/bin"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'

echo "\n${CYAN}═══ DotFiles init ═══════════════════════════════════${RESET}\n"

# ── Make scripts executable ───────────────────────────────────────────────────
chmod +x "$REPO_DIR/bin/dsync-up" "$REPO_DIR/bin/dsync-down"
echo "  ${GREEN}✔${RESET}  Scripts marked executable"

# ── Symlink to ~/.local/bin ───────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

for script in dsync-up dsync-down; do
  target="$BIN_DIR/$script"
  if [[ -L "$target" ]]; then
    echo "  ${GREEN}✔${RESET}  $script already symlinked, skipping"
  else
    ln -s "$REPO_DIR/bin/$script" "$target"
    echo "  ${GREEN}✔${RESET}  Symlinked $script → $target"
  fi
done

echo "\n  ${GREEN}Done.${RESET} You can now run dsync-up and dsync-down from anywhere."
echo "  Next: run 'dsync-down' to apply configs to this machine.\n"
