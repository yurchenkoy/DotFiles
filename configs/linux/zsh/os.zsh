# linux/zsh/os.zsh — Linux plugin locations + env consumed by common.zsh.
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"
ZSH_PLUGIN_FZF_TAB="$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"
ZSH_PLUGIN_FSH="$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
ZSH_COMPLETIONS_FPATH="$ZSH_PLUGINS/zsh-completions/src"
export FAST_WORK_DIR="$HOME/.config/fsh"

# Packaged by the distro, and the path differs: Fedora drops it in /usr/share, Arch
# nests it under /usr/share/zsh/plugins. First one that exists wins.
ZSH_PLUGIN_AUTOSUGGEST=""
for _p in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
  [[ -r "$_p" ]] && { ZSH_PLUGIN_AUTOSUGGEST="$_p"; break; }
done
unset _p
