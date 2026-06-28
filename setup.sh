#!/usr/bin/env zsh
# setup.sh — universal bootstrap. Detects OS, symlinks scripts, then OS-specific steps.
set -euo pipefail
REPO_DIR="${0:A:h}"; SCRIPTS_DIR="$REPO_DIR/scripts"; BIN_DIR="$HOME/.local/bin"
source "$REPO_DIR/scripts/lib/config-map.zsh"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
OS="$(df_os)"
echo "\n${CYAN}═══ DotFiles setup ($OS) ═══════════════════════${RESET}\n"

# --- shared: symlink scripts (excluding lib/) into ~/.local/bin ---
mkdir -p "$BIN_DIR"
for link in "$BIN_DIR"/*(N); do
  [[ -L "$link" ]] || continue
  [[ "$(readlink "$link")" == "$REPO_DIR"/* && ! -e "$link" ]] && { rm "$link"; echo "  ${YELLOW}✔${RESET} removed stale $(basename "$link")"; }
done
for script in "$SCRIPTS_DIR"/*(.N); do
  name="$(basename "$script")"; chmod +x "$script"; tgt="$BIN_DIR/$name"
  [[ -L "$tgt" ]] && rm "$tgt"; ln -s "$script" "$tgt"; echo "  ${GREEN}✔${RESET} symlinked $name"
done

if [[ "$OS" == mac ]]; then
  echo "\n  Next (macOS):"
  echo "    1. /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo "    2. brew bundle --file=$REPO_DIR/packages/Brewfile"
  echo "    3. dotfiles-distribute"
  echo "    4. chmod go-w \"\$(brew --prefix)/share\" \"\$(brew --prefix)/share/zsh-completions\""
  echo "    5. place your GPG signing key (see secrets/signing.template)"
else
  echo "\n  ${CYAN}Automating unprivileged Linux bootstrap...${RESET}"
  PLUG="$HOME/.local/share/zsh/plugins"; mkdir -p "$PLUG"
  typeset -A PLUGINS=(
    fzf-tab Aloxaf/fzf-tab
    zsh-completions zsh-users/zsh-completions
    fast-syntax-highlighting zdharma-continuum/fast-syntax-highlighting
  )
  for dir url in "${(@kv)PLUGINS}"; do
    [[ -d "$PLUG/$dir" ]] && continue
    if git clone --depth=1 "https://github.com/$url" "$PLUG/$dir" 2>/dev/null; then
      echo "  ${GREEN}✔${RESET} plugin $dir"
    else
      echo "  ${YELLOW}⚠${RESET} could not clone $dir"
    fi
  done
  if command -v systemctl &>/dev/null; then
    systemctl --user enable --now ssh-agent.service 2>/dev/null && echo "  ${GREEN}✔${RESET} ssh-agent.service" || true
  fi
  echo "  ${YELLOW}Run dotfiles-distribute, then finish these steps:${RESET}"
  echo "    • apply fsh theme (regenerates the cache): fast-theme XDG:tokyodark"
  echo "    • install packages per packages/linux-packages.md (dnf/COPR/manual)"
  echo "    • install nerd fonts into ~/.local/share/fonts/ then: fc-cache -f"
  echo "    • install xremap binary to /usr/local/bin/xremap"
  echo "    • greetd/tuigreet, KeePassXC SSH-agent setup, GitHub signing key upload"
fi
echo "\n  ${GREEN}Done.${RESET}"
