#!/usr/bin/env zsh
# config-map.zsh — single source of truth for collect/distribute. Sourced, not run.
# Record format: label|applies|type|repo_path|mac_live|linux_live   (applies: both|mac|linux)
# Use "-" for a live path that does not apply to that OS.

df_os() { [[ "$(uname)" == "Darwin" ]] && print -r -- mac || print -r -- linux }

typeset -ga DOTFILES_RECORDS=(
  # --- common entrypoints (pure includes) ---
  "zshrc|both|file|configs/common/zsh/zshrc|$HOME/.zshrc|$HOME/.zshrc"
  "ghostty|both|file|configs/common/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config|$HOME/.config/ghostty/config"
  "gitconfig|both|file|configs/common/git/gitconfig|$HOME/.gitconfig|$HOME/.gitconfig"
  # --- common fragments / single files ---
  "zsh-common|both|file|configs/common/zsh/common.zsh|$HOME/.config/zsh/common.zsh|$HOME/.config/zsh/common.zsh"
  "ghostty-base|both|file|configs/common/ghostty/config-base|$HOME/Library/Application Support/com.mitchellh.ghostty/config-base|$HOME/.config/ghostty/config-base"
  "git-common|both|file|configs/common/git/common.gitconfig|$HOME/.config/git/common.gitconfig|$HOME/.config/git/common.gitconfig"
  "starship|both|file|configs/common/starship/starship.toml|$HOME/.config/starship.toml|$HOME/.config/starship.toml"
  "fsh|both|dir|configs/common/fsh|$HOME/.config/fsh|$HOME/.config/fsh"
  "nvim|both|dir|configs/common/nvim|$HOME/.config/nvim|$HOME/.config/nvim"
  # --- os fragments ---
  "zsh-os|mac|file|configs/macos/zsh/os.zsh|$HOME/.config/zsh/os.zsh|-"
  "zsh-os|linux|file|configs/linux/zsh/os.zsh|-|$HOME/.config/zsh/os.zsh"
  "ghostty-os|mac|file|configs/macos/ghostty/config-os|$HOME/Library/Application Support/com.mitchellh.ghostty/config-os|-"
  "ghostty-os|linux|file|configs/linux/ghostty/config-os|-|$HOME/.config/ghostty/config-os"
  "git-signing|mac|file|configs/macos/git/signing|$HOME/.config/git/signing|-"
  "git-signing|linux|file|configs/linux/git/signing|-|$HOME/.config/git/signing"
  # --- mac-only ---
  "karabiner|mac|file|configs/macos/karabiner/karabiner.json|$HOME/.config/karabiner/karabiner.json|-"
  "aerospace|mac|file|configs/macos/aerospace/aerospace.toml|$HOME/.config/aerospace/aerospace.toml|-"
  "alfred|mac|dir|configs/macos/alfred/Alfred.alfredpreferences|$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences|-"
  # --- linux-only ---
  "xremap|linux|file|configs/linux/xremap/config.yml|-|$HOME/.config/xremap/config.yml"
  "hypr|linux|file|configs/linux/hypr/hyprland.conf|-|$HOME/.config/hypr/hyprland.conf"
  "environmentd|linux|file|configs/linux/environment.d/ssh-agent.conf|-|$HOME/.config/environment.d/ssh-agent.conf"
)

# df_each <callback>: calls `callback label type repo_path live_path` for every record
# that applies to the current OS (skips records whose live path for this OS is "-").
df_each() {
  local cb="$1" os; os="$(df_os)"
  local rec label applies type repo mac_live linux_live live
  for rec in "${DOTFILES_RECORDS[@]}"; do
    IFS='|' read -r label applies type repo mac_live linux_live <<< "$rec"
    [[ "$applies" == "both" || "$applies" == "$os" ]] || continue
    [[ "$os" == "mac" ]] && live="$mac_live" || live="$linux_live"
    [[ "$live" == "-" ]] && continue
    "$cb" "$label" "$type" "$repo" "$live"
  done
}
