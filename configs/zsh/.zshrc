export EDITOR="/opt/homebrew/bin/nvim"
export VISUAL="nvim"

# --- Python related ---
alias python='python3.11'
export PATH="$HOME/.local/bin:$PATH"
WORK_VENVS="$HOME/Documents/PythonEnvs"

activate() {
  if [ -z "$1" ]; then
    echo "Usage: pythonenv <env-name>"
    return 1
  fi

  local env_path="$WORK_VENVS/$1"

  if [ ! -d "$env_path" ]; then
    echo "Environment not found: $env_path"
    return 1
  fi

  source "$env_path/bin/activate"
}

# --- END ---

# --- Aliases ---
alias ls='eza'

# --- Initialize Completions ---
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# Case-insensitive completion (lowercase matches Uppercase)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}'

# --- Remove / from WORDCHARS (deletion stops at path separators) ---
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'


# ─────────────────────────────────────────────────────────────
# LS_COLORS  (Tokyo Dark+ palette)
# ─────────────────────────────────────────────────────────────
export LS_COLORS="\
di=1;38;5;111:\
ln=38;5;107:\
so=38;5;117:\
pi=38;5;179:\
ex=1;38;5;107:\
bd=38;5;179;1:\
cd=38;5;179;1:\
su=38;5;210;1:\
sg=38;5;210;1:\
tw=38;5;111;1:\
ow=38;5;111:\
st=38;5;141:\
or=38;5;210;4:\
mi=38;5;210;4:\
*.tar=38;5;210:\
*.tgz=38;5;210:\
*.zip=38;5;210:\
*.gz=38;5;210:\
*.bz2=38;5;210:\
*.xz=38;5;210:\
*.7z=38;5;210:\
*.rar=38;5;210:\
*.dmg=38;5;210:\
*.iso=38;5;210:\
*.py=38;5;111:\
*.js=38;5;179:\
*.ts=38;5;111:\
*.jsx=38;5;179:\
*.tsx=38;5;111:\
*.sh=38;5;107:\
*.zsh=38;5;107:\
*.bash=38;5;107:\
*.json=38;5;152:\
*.yaml=38;5;152:\
*.yml=38;5;152:\
*.toml=38;5;152:\
*.env=38;5;179:\
*.md=38;5;189:\
*.txt=38;5;189:\
*.pdf=38;5;141:\
*.png=38;5;117:\
*.jpg=38;5;117:\
*.jpeg=38;5;117:\
*.gif=38;5;117:\
*.svg=38;5;117:\
*.mp4=38;5;179:\
*.mov=38;5;179:\
*.mp3=38;5;179:\
*.flac=38;5;179:\
*.go=38;5;117:\
*.rs=38;5;210:\
*.c=38;5;152:\
*.cpp=38;5;152:\
*.h=38;5;152:\
*.html=38;5;141:\
*.css=38;5;141:\
*.scss=38;5;141:\
*.sql=38;5;117:\
*.lock=38;5;60:\
*.log=38;5;60:\
*.tmp=38;5;60:\
*.bak=38;5;60:\
"


# --- Load fzf-tab ---
source "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"

# Init zoxide
eval "$(zoxide init zsh)"   # or bash

# Project picker: Ctrl+P opens fuzzy finder scoped to git repos
prj() {
  local dir
  dir=$(find ~/Documents/ -maxdepth 3 -name ".git" -type d 2>/dev/null \
        | sed 's|/.git||' \
        | fzf \
            --delimiter '/' \
            --with-nth -1 \
            --height '~40%' \
            --min-height 5 \
            --border rounded \
            --margin '0,49%,0,0' \
            --prompt " project> " \
            --pointer "▶" \
            --color "border:#89b4fa,prompt:#cba6f7,pointer:#f38ba8")
  [ -n "$dir" ] && cd "$dir"
}

bindkey -s '^p' 'prj\n'   # Ctrl+P triggers it (zsh)

# ─────────────────────────────────────────────────────────────
# fzf-tab settings  (Tokyo Dark+ palette)
# ─────────────────────────────────────────────────────────────

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Enable group support via descriptions
zstyle ':completion:*:descriptions' format '[%d]'

# Feed LS_COLORS into completion list (enables per-extension coloring)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Force zsh not to show completion menu, letting fzf-tab capture it
zstyle ':completion:*' menu no

# Preview directory contents with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# Core fzf color flags — Tokyo Dark+ palette
# NOTE: No --bind=tab:accept here — Tab is handled by our custom widget below
zstyle ':fzf-tab:*' fzf-flags \
  --color=fg:#c0caf5 \
  --color=fg+:#ffffff \
  --color=bg:#24283b \
  --color=bg+:#38478e \
  --color=hl:#7AA2F7 \
  --color=hl+:#7DCFFF \
  --color=info:#c0caf5 \
  --color=border:#414868 \
  --color=prompt:#7AA2F7 \
  --color=pointer:#7AA2F7 \
  --color=marker:#9ECE6A \
  --color=spinner:#7AA2F7 \
  --color=header:#565f89 \
  --color=preview-fg:#c0caf5 \
  --color=preview-bg:#1d1f2d \
  --color=gutter:#24283b

# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Use Enter to accept fzf-tab selection (Tab is reserved for suggestion-to-slash)
zstyle ':fzf-tab:*' fzf-bindings 'enter:accept'


# ---- Prompt (Starship) ----
eval "$(starship init zsh)"

# ---- Load Fast Syntax Highlighting (must come after FAST_HIGHLIGHT_STYLES) ----
source "$(brew --prefix)/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ─────────────────────────────────────────────────────────────
# Auto Suggestion Settings
# ─────────────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HISTORY_IGNORE_CASE=1

# ── Accept suggestion up to next / (Tab) ──
# If a suggestion is visible: accept up to the next path separator.
# If no suggestion: open fzf-tab completion picker (Shift+Tab does the same).
_accept_suggestion_to_slash() {
  local suggestion="${POSTDISPLAY}"
  if [[ -z "$suggestion" ]]; then
    zle fzf-tab-complete
    return
  fi
  local slash_pos="${suggestion%%/*}"
  if [[ "$suggestion" == */* ]]; then
    LBUFFER+="${slash_pos}/"
    POSTDISPLAY="${suggestion#*/}"
  else
    LBUFFER+="$suggestion"
    POSTDISPLAY=""
  fi
  _zsh_highlight
}

zle -N _accept_suggestion_to_slash
bindkey '^I' _accept_suggestion_to_slash        # Tab

# ── Accept full autosuggestion (Right Arrow) ──
_accept_or_forward_char() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle autosuggest-accept
    _zsh_highlight
  else
    zle forward-char
  fi
}

zle -N _accept_or_forward_char
bindkey '^[[C' _accept_or_forward_char
bindkey '\eOC'  _accept_or_forward_char

# ── Open fzf-tab picker (Shift+Tab) ──
bindkey '^[[Z' fzf-tab-complete                 # Shift+Tab


# ---- Load zsh-autosuggestions (must be last) ----
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

