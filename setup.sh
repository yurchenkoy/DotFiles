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

# --- shared: ensure the Python virtualenv home exists (activate/venv rely on it) ---
VENV_DIR="$HOME/Documents/PythonEnvs"
mkdir -p "$VENV_DIR" && echo "  ${GREEN}✔${RESET} python venv home: $VENV_DIR"
for link in "$BIN_DIR"/*(N); do
  [[ -L "$link" ]] || continue
  [[ "$(readlink "$link")" == "$REPO_DIR"/* && ! -e "$link" ]] && { rm "$link"; echo "  ${YELLOW}✔${RESET} removed stale $(basename "$link")"; }
done
for script in "$SCRIPTS_DIR"/*(.N); do
  name="$(basename "$script")"; chmod +x "$script"; tgt="$BIN_DIR/$name"
  [[ -L "$tgt" ]] && rm "$tgt"; ln -s "$script" "$tgt"; echo "  ${GREEN}✔${RESET} symlinked $name"
done

# --- shared: per-machine git config. Must be a plain file, not a symlink, so gh and
#     `git config --global` write here instead of into the repo's tracked config. ---
touch "$HOME/.gitconfig" && echo "  ${GREEN}✔${RESET} per-machine git config: ~/.gitconfig"

if [[ "$OS" == mac ]]; then
  echo "\n  Next (macOS):"
  echo "    1. /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo "    2. brew bundle --file=$REPO_DIR/packages/Brewfile"
  echo "    3. dotfiles-distribute"
  echo "    4. chmod go-w \"\$(brew --prefix)/share\" \"\$(brew --prefix)/share/zsh-completions\""
  echo "    5. Proton Pass: enable its SSH agent + unlock (commit signing); gh auth login (Yes to git credentials)"
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
  echo "  ${YELLOW}Run dotfiles-distribute, then finish these steps:${RESET}"
  echo "    • generate desktop theme colors (required): scripts/theme-apply"
  echo "    • apply fsh theme (regenerates the cache): fast-theme XDG:tokyodark"
  echo "    • install packages per packages/linux-packages.md (Fedora and Arch columns)"
  echo "    • install nerd fonts (packaged on Arch; else manual + fc-cache -f)"
  echo "    • install xremap (AUR on Arch; else prebuilt binary to /usr/local/bin)"
  echo "    • optional: a wallpaper at ~/Pictures/Wallpapers/tokyonight.jpg (else a solid colour)"
  echo "    • greetd/tuigreet, a polkit agent, Proton Pass SSH agent, gh auth login (Yes to git credentials)"
fi
echo "\n  ${GREEN}Done.${RESET}"
