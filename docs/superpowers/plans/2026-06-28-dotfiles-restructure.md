# DotFiles Restructure (macOS + Linux) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the DotFiles repo into `common/macos/linux` so one repo provisions both a macOS and a Linux machine, with OS-aware sync scripts, without the platforms drifting apart.

**Architecture:** Copy-based sync is retained. Divergent configs (zsh, git, ghostty) use base + per-OS fragment wired via each tool's native include; everything else is a single file in `common/`, `macos/`, or `linux/`. The collect/distribute scripts share one OS-tagged config-map (extracted into a lib) and filter by `uname`.

**Tech Stack:** zsh scripts, rsync/cp, fzf, git includes, ghostty `config-file`, zsh `source`.

## Global Constraints

- Repo root: `/home/yuy/Documents/DotFiles` (this Linux machine). Work on branch `repo-restructure`.
- macOS side is NOT verifiable on this machine — derive mac fragments from the existing repo's
  current `configs/*` (which are the mac versions) and flag for the user to verify on the Mac.
- The live Linux machine must keep working after every task (each split is distributed + verified
  in a fresh `zsh -i -c` / `ghostty +show-config` / throwaway signed commit before commit).
- Scripts/setup must run as the user with NO sudo (privileged steps are printed, not executed).
- `secrets/` is gitignored except its template; scripts never read/write `secrets/`.
- Commit signing is on (`commit.gpgsign=true`); the ssh-agent must hold the key when committing
  (`export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket; ssh-add -l` should list it).
- Entry-point ordering: **zsh sources os.zsh THEN common.zsh** (common consumes plugin-path vars
  set by os); **ghostty** loads `config-base` THEN `config-os` (os overrides); **git** includes
  `common.gitconfig` THEN `signing`.
- Live paths (pipe-delimited so spaces are safe). Mac ghostty dir =
  `$HOME/Library/Application Support/com.mitchellh.ghostty`.

---

### Task 1: Branch + skeleton + secrets scaffold

**Files:**
- Create dirs: `configs/common/{starship,fsh,nvim,zsh,ghostty,git}`, `configs/macos/{zsh,ghostty,git,karabiner,aerospace,alfred}`, `configs/linux/{zsh,ghostty,git,xremap,hypr,environment.d}`, `packages/`, `secrets/`, `scripts/lib/`
- Create: `secrets/.gitignore`, `secrets/signing.template`

- [ ] **Step 1: Create branch**

```bash
cd /home/yuy/Documents/DotFiles
git checkout -b repo-restructure
```

- [ ] **Step 2: Create the directory skeleton**

```bash
cd /home/yuy/Documents/DotFiles
mkdir -p configs/common/{starship,fsh,nvim,zsh,ghostty,git} \
         configs/macos/{zsh,ghostty,git,karabiner,aerospace,alfred} \
         configs/linux/{zsh,ghostty,git,xremap,hypr,environment.d} \
         packages secrets scripts/lib
```

- [ ] **Step 3: Write `secrets/.gitignore` (allow-list only)**

```gitignore
# Ignore everything in secrets/ EXCEPT this file and the template.
*
!.gitignore
!signing.template
```

- [ ] **Step 4: Write `secrets/signing.template`**

```text
# secrets/signing.template — copy/rename per machine; the REAL key material in
# this folder is gitignored. This documents what each OS expects.
#
# LINUX (SSH signing via KeePassXC + ssh-agent):
#   1. Put your ed25519 keypair here (or keep it only in KeePassXC):
#        secrets/git_signing_ed25519        (private; gitignored)
#        secrets/git_signing_ed25519.pub    (public;  gitignored)
#   2. configs/linux/git/signing already points user.signingkey at the .pub path.
#   3. Load it into the agent via KeePassXC (or `ssh-add`).
#
# MACOS (GPG signing):
#   1. Your GPG private key lives in the GPG keyring (optionally back it up here).
#   2. configs/macos/git/signing sets user.signingkey = <your GPG key id>.
#
# If the referenced key is absent, signing fails and the commit is blocked
# (intentional: never produce an accidental unsigned commit).
```

- [ ] **Step 5: Verify the skeleton + gitignore**

Run:
```bash
cd /home/yuy/Documents/DotFiles
find configs packages secrets scripts/lib -type d | sort
printf 'secret\n' > secrets/__probe && git check-ignore secrets/__probe && rm secrets/__probe
git check-ignore secrets/signing.template; echo "template ignored? exit=$? (expect 1 = NOT ignored)"
```
Expected: all dirs listed; `secrets/__probe` is ignored (printed); `signing.template` exit=1 (tracked).

- [ ] **Step 6: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add configs secrets scripts/lib packages 2>/dev/null; git add secrets/.gitignore secrets/signing.template
git commit -m "chore: scaffold common/macos/linux layout + secrets guard"
```

---

### Task 2: Shared OS-aware config-map lib

**Files:**
- Create: `scripts/lib/config-map.zsh`

**Interfaces:**
- Produces: `df_os()` → prints `mac`|`linux`. `DOTFILES_RECORDS` array of
  `label|applies|type|repo_path|mac_live|linux_live`. `df_each` helper that, for the current OS,
  yields applicable records as `label\ttype\trepo_path\tlive_path` via a callback.

- [ ] **Step 1: Write `scripts/lib/config-map.zsh`**

```zsh
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
```

- [ ] **Step 2: Verify the lib parses and filters by OS**

Run:
```bash
cd /home/yuy/Documents/DotFiles
zsh -c 'source scripts/lib/config-map.zsh; echo "os=$(df_os)"; df_each() { :; }; print_rec(){ print -r -- "$1 -> $4"; }; ' 2>&1 | head
zsh -c 'source scripts/lib/config-map.zsh; print_rec(){ print -r -- "$1\t$2\t$4"; }; df_each print_rec'
```
Expected: `os=linux`; the printed list includes common + linux rows (zshrc, zsh-common, zsh-os→linux, ghostty*, git*, starship, fsh, nvim, xremap, hypr, environmentd) and **excludes** all mac-only rows (karabiner, aerospace, alfred) and the mac `*-os` variants.

- [ ] **Step 3: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add scripts/lib/config-map.zsh
git commit -m "feat: OS-aware shared config-map lib for collect/distribute"
```

---

### Task 3: Rewrite collect + distribute on the shared lib

**Files:**
- Modify (rewrite): `scripts/dotfiles-distribute`, `scripts/dotfiles-collect`

**Interfaces:**
- Consumes: `scripts/lib/config-map.zsh` (`df_os`, `df_each`).

- [ ] **Step 1: Rewrite `scripts/dotfiles-distribute`**

```zsh
#!/usr/bin/env zsh
# dotfiles-distribute — copy configs FROM the repo into live locations (OS-aware).
# Usage: dotfiles-distribute [--dry-run] [--force]
set -euo pipefail

if [[ -n "${DOTFILES_DIR:-}" ]]; then REPO_DIR="$DOTFILES_DIR"
else
  REPO_DIR=$(find "$HOME/Documents" -maxdepth 3 -type d -name "DotFiles" 2>/dev/null | head -1)
  [[ -z "$REPO_DIR" || ! -f "$REPO_DIR/setup.sh" ]] && { echo "  ✖  DotFiles repo not found; set \$DOTFILES_DIR."; exit 1; }
fi
source "$REPO_DIR/scripts/lib/config-map.zsh"

DRY_RUN=0; FORCE=0
for a in "$@"; do [[ "$a" == "--dry-run" ]] && DRY_RUN=1; [[ "$a" == "--force" ]] && FORCE=1; done
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
echo "\n${CYAN}═══ dotfiles-distribute ($(df_os)) ════════════════${RESET}"
[[ $DRY_RUN -eq 1 ]] && echo "  ${YELLOW}DRY RUN${RESET}"

# selection (fzf when available and not --force)
typeset -A SEL=(); typeset -a LABELS=(); typeset -A LTYPE LREPO LLIVE
collect_meta(){ LABELS+=("$1"); LTYPE[$1]="$2"; LREPO[$1]="$3"; LLIVE[$1]="$4"; }
df_each collect_meta
if [[ $FORCE -eq 1 ]]; then for l in "${LABELS[@]}"; do SEL[$l]=1; done
elif command -v fzf &>/dev/null; then
  chosen=$(printf '%s\n' "${LABELS[@]}" | fzf --multi --height=~60% --layout=reverse --border=rounded \
    --prompt="  distribute > " --header="Tab·toggle Ctrl-A·all Enter·confirm" \
    --bind="ctrl-a:select-all,ctrl-d:deselect-all") || { echo "  Cancelled."; exit 0; }
  [[ -z "$chosen" ]] && { echo "  Nothing selected."; exit 0; }
  while IFS= read -r l; do SEL[$l]=1; done <<< "$chosen"
else for l in "${LABELS[@]}"; do SEL[$l]=1; done; fi

# diff preview
diff_found=0
for l in "${LABELS[@]}"; do
  [[ -z "${SEL[$l]:-}" ]] && continue
  src="$REPO_DIR/${LREPO[$l]}"; dst="${LLIVE[$l]}"; kind="${LTYPE[$l]}"
  [[ ! -e "$src" ]] && { echo "  ${YELLOW}⚠${RESET}  not in repo: $l"; continue; }
  if [[ ! -e "$dst" ]]; then echo "  ${GREEN}+${RESET}  new: $dst"; diff_found=1; continue; fi
  if [[ "$kind" == file ]]; then
    if ! diff -q "$src" "$dst" &>/dev/null; then echo "  ${YELLOW}~${RESET}  changed: $dst"; diff_found=1
    else echo "  ${GREEN}✔${RESET}  up to date: $l"; fi
  else
    d=$(rsync -an --delete --out-format="%n" "$src/" "$dst/" 2>/dev/null || true)
    [[ -n "$d" ]] && { echo "  ${YELLOW}~${RESET}  dir changed: $dst"; diff_found=1; } || echo "  ${GREEN}✔${RESET}  up to date: $l"
  fi
done
[[ $diff_found -eq 0 ]] && { echo "  ${GREEN}Nothing to do.${RESET}"; exit 0; }
[[ $DRY_RUN -eq 1 ]] && exit 0
if [[ $FORCE -eq 0 ]]; then echo -n "  Apply? (y/N) "; read -r r; [[ "$r" != [yY] ]] && { echo "  Cancelled."; exit 0; }; fi

# apply
for l in "${LABELS[@]}"; do
  [[ -z "${SEL[$l]:-}" ]] && continue
  src="$REPO_DIR/${LREPO[$l]}"; dst="${LLIVE[$l]}"; kind="${LTYPE[$l]}"
  [[ ! -e "$src" ]] && continue
  if [[ "$kind" == dir ]]; then mkdir -p "$dst"; rsync -a --delete "$src/" "$dst/"
  else mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; fi
  echo "  ${GREEN}✔${RESET}  → $dst"
done
echo "  ${GREEN}Done.${RESET} Restart your shell or: source ~/.zshrc"
```

- [ ] **Step 2: Rewrite `scripts/dotfiles-collect`** (mirror of distribute, reversed direction + Brewfile on mac)

```zsh
#!/usr/bin/env zsh
# dotfiles-collect — copy live configs INTO the repo (OS-aware).
# Usage: dotfiles-collect [--dry-run] [--force]
set -euo pipefail

if [[ -n "${DOTFILES_DIR:-}" ]]; then REPO_DIR="$DOTFILES_DIR"
else
  REPO_DIR=$(find "$HOME/Documents" -maxdepth 3 -type d -name "DotFiles" 2>/dev/null | head -1)
  [[ -z "$REPO_DIR" || ! -f "$REPO_DIR/setup.sh" ]] && { echo "  ✖  DotFiles repo not found; set \$DOTFILES_DIR."; exit 1; }
fi
source "$REPO_DIR/scripts/lib/config-map.zsh"

DRY_RUN=0; FORCE=0
for a in "$@"; do [[ "$a" == "--dry-run" ]] && DRY_RUN=1; [[ "$a" == "--force" ]] && FORCE=1; done
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
echo "\n${CYAN}═══ dotfiles-collect ($(df_os)) ════════════════${RESET}"
[[ $DRY_RUN -eq 1 ]] && echo "  ${YELLOW}DRY RUN${RESET}"

typeset -A SEL=(); typeset -a LABELS=(); typeset -A LTYPE LREPO LLIVE
collect_meta(){ LABELS+=("$1"); LTYPE[$1]="$2"; LREPO[$1]="$3"; LLIVE[$1]="$4"; }
df_each collect_meta
BREW=0
if [[ $FORCE -eq 1 ]]; then for l in "${LABELS[@]}"; do SEL[$l]=1; done; [[ "$(df_os)" == mac ]] && BREW=1
elif command -v fzf &>/dev/null; then
  menu=("${LABELS[@]}"); [[ "$(df_os)" == mac ]] && menu+=("Brewfile")
  chosen=$(printf '%s\n' "${menu[@]}" | fzf --multi --height=~60% --layout=reverse --border=rounded \
    --prompt="  collect > " --header="Tab·toggle Ctrl-A·all Enter·confirm" \
    --bind="ctrl-a:select-all,ctrl-d:deselect-all") || { echo "  Cancelled."; exit 0; }
  [[ -z "$chosen" ]] && { echo "  Nothing selected."; exit 0; }
  while IFS= read -r l; do [[ "$l" == "Brewfile" ]] && BREW=1 || SEL[$l]=1; done <<< "$chosen"
else for l in "${LABELS[@]}"; do SEL[$l]=1; done; [[ "$(df_os)" == mac ]] && BREW=1; fi

diff_found=0
for l in "${LABELS[@]}"; do
  [[ -z "${SEL[$l]:-}" ]] && continue
  live="${LLIVE[$l]}"; dst="$REPO_DIR/${LREPO[$l]}"; kind="${LTYPE[$l]}"
  [[ ! -e "$live" ]] && { echo "  ${YELLOW}⚠${RESET}  not found live: $l"; continue; }
  if [[ ! -e "$dst" ]]; then echo "  ${GREEN}+${RESET}  new in repo: $l"; diff_found=1; continue; fi
  if [[ "$kind" == file ]]; then
    if ! diff -q "$dst" "$live" &>/dev/null; then echo "  ${YELLOW}~${RESET}  changed: $l"; diff_found=1
    else echo "  ${GREEN}✔${RESET}  up to date: $l"; fi
  else
    d=$(rsync -an --delete --out-format="%n" "$live/" "$dst/" 2>/dev/null || true)
    [[ -n "$d" ]] && { echo "  ${YELLOW}~${RESET}  dir changed: $l"; diff_found=1; } || echo "  ${GREEN}✔${RESET}  up to date: $l"
  fi
done
[[ $BREW -eq 1 ]] && command -v brew &>/dev/null && { echo "  ${YELLOW}~${RESET}  Brewfile refresh"; diff_found=1; }
[[ $diff_found -eq 0 ]] && { echo "  ${GREEN}Nothing to do.${RESET}"; exit 0; }
[[ $DRY_RUN -eq 1 ]] && exit 0
if [[ $FORCE -eq 0 ]]; then echo -n "  Collect? (y/N) "; read -r r; [[ "$r" != [yY] ]] && { echo "  Cancelled."; exit 0; }; fi

for l in "${LABELS[@]}"; do
  [[ -z "${SEL[$l]:-}" ]] && continue
  live="${LLIVE[$l]}"; dst="$REPO_DIR/${LREPO[$l]}"; kind="${LTYPE[$l]}"
  [[ ! -e "$live" ]] && continue
  if [[ "$kind" == dir ]]; then mkdir -p "$dst"; rsync -a --delete "$live/" "$dst/"
  else mkdir -p "$(dirname "$dst")"; cp "$live" "$dst"; fi
  echo "  ${GREEN}✔${RESET}  $live → $dst"
done
[[ $BREW -eq 1 ]] && command -v brew &>/dev/null && { brew bundle dump --force --file="$REPO_DIR/packages/Brewfile"; echo "  ${GREEN}✔${RESET}  Brewfile updated"; }
echo "  ${GREEN}Done.${RESET} Review: cd $REPO_DIR && git diff"
```

- [ ] **Step 3: Verify both run and detect OS (nothing seeded yet → mostly "not in repo")**

Run:
```bash
cd /home/yuy/Documents/DotFiles
chmod +x scripts/dotfiles-collect scripts/dotfiles-distribute
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --dry-run --force 2>&1 | head -20
```
Expected: header shows `(linux)`; lists common+linux labels; entries not yet seeded show `not in repo`; no crash.

- [ ] **Step 4: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add scripts/dotfiles-collect scripts/dotfiles-distribute
git commit -m "feat: OS-aware collect/distribute on shared config-map"
```

---

### Task 4: Seed common-only configs (starship, fsh, nvim)

**Files:**
- Move: `configs/starship` → `configs/common/starship`; `configs/fsh` → `configs/common/fsh`;
  `configs/nvim` → `configs/common/nvim`

These three are byte-identical across OSes (the live Linux copies were deployed from these repo
files this session), so relocation is all that's needed.

- [ ] **Step 1: git mv the three configs into common/**

```bash
cd /home/yuy/Documents/DotFiles
git mv configs/starship/starship.toml configs/common/starship/starship.toml
git mv configs/fsh configs/common/fsh 2>/dev/null || { mkdir -p configs/common/fsh; git mv configs/fsh/* configs/common/fsh/; }
rsync -a --delete configs/nvim/ configs/common/nvim/ && git rm -r --quiet configs/nvim && git add configs/common/nvim
rmdir configs/starship 2>/dev/null || true
```

- [ ] **Step 2: Verify distribute sees them up-to-date on this machine**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --dry-run --force 2>&1 | grep -E 'starship|fsh|nvim'
```
Expected: `up to date: starship`, `up to date: fsh`, `up to date: nvim` (live already matches).

- [ ] **Step 3: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add -A
git commit -m "refactor: move starship/fsh/nvim to configs/common"
```

---

### Task 5: Split zsh (entrypoint + common.zsh + linux os.zsh + mac os.zsh)

**Files:**
- Create: `configs/common/zsh/zshrc`, `configs/common/zsh/common.zsh`,
  `configs/linux/zsh/os.zsh`, `configs/macos/zsh/os.zsh`
- Backup: `~/.zshrc.pre-restructure`

**Interfaces:**
- Produces: live `~/.config/zsh/{common.zsh,os.zsh}` + entrypoint `~/.zshrc`. os.zsh defines
  `ZSH_PLUGIN_FZF_TAB`, `ZSH_PLUGIN_FSH`, `ZSH_PLUGIN_AUTOSUGGEST`, `ZSH_COMPLETIONS_FPATH`
  (consumed by common.zsh), and on linux `export FAST_WORK_DIR`.

- [ ] **Step 1: Back up the current live `.zshrc`**

```bash
cp ~/.zshrc ~/.zshrc.pre-restructure
```

- [ ] **Step 2: Write the entrypoint `configs/common/zsh/zshrc`**

```zsh
# ~/.zshrc — entrypoint. OS fragment first (sets plugin-path vars + early env),
# then the shared bulk which consumes them.
source "${ZDOTDIR:-$HOME/.config/zsh}/os.zsh"
source "${ZDOTDIR:-$HOME/.config/zsh}/common.zsh"
```

- [ ] **Step 3: Write `configs/linux/zsh/os.zsh`**

```zsh
# linux/zsh/os.zsh — Linux plugin locations + env consumed by common.zsh.
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"
ZSH_PLUGIN_FZF_TAB="$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"
ZSH_PLUGIN_FSH="$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
ZSH_PLUGIN_AUTOSUGGEST="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_COMPLETIONS_FPATH="$ZSH_PLUGINS/zsh-completions/src"
export FAST_WORK_DIR="$HOME/.config/fsh"
```

- [ ] **Step 4: Write `configs/macos/zsh/os.zsh`** (derived from the pre-restructure mac `.zshrc`; unverified on this machine)

```zsh
# macos/zsh/os.zsh — Homebrew plugin locations consumed by common.zsh.
ZSH_PLUGIN_FZF_TAB="/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
ZSH_PLUGIN_FSH="$(brew --prefix)/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
ZSH_PLUGIN_AUTOSUGGEST="/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_COMPLETIONS_FPATH="$(brew --prefix)/share/zsh-completions"
```

- [ ] **Step 5: Create `configs/common/zsh/common.zsh` from the current live `.zshrc` with plugin lines parameterized**

Start from the current `~/.zshrc.pre-restructure` and apply exactly these edits to produce
`configs/common/zsh/common.zsh`:
1. **Delete** the lines now owned by os.zsh: the `ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"`
   line and the `export FAST_WORK_DIR=...` line.
2. **Replace** the completions block
   `fpath=("$ZSH_PLUGINS/zsh-completions/src" $fpath)` → `fpath=("$ZSH_COMPLETIONS_FPATH" $fpath)`.
3. **Replace** `source "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"` →
   `source "$ZSH_PLUGIN_FZF_TAB"`.
4. **Replace** `source "$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"`
   → `source "$ZSH_PLUGIN_FSH"`.
5. **Replace** `source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh` →
   `source "$ZSH_PLUGIN_AUTOSUGGEST"`.
6. Keep everything else verbatim (EDITOR/VISUAL, bindkey -e, `bindkey '^U' kill-whole-line`,
   PATH, WORK_VENVS/activate, `alias ls='eza'`, compinit + matcher-list, WORDCHARS, LS_COLORS,
   zoxide init, prj() + `^p` bind, all fzf-tab zstyles, starship init, autosuggest settings,
   the Tab/Right-arrow widgets + binds, GPG_TTY).

Command to scaffold it (then hand-verify the 5 edits above are applied):
```bash
cd /home/yuy/Documents/DotFiles
cp ~/.zshrc.pre-restructure configs/common/zsh/common.zsh
sed -i '/^ZSH_PLUGINS="\$HOME\/\.local\/share\/zsh\/plugins"$/d' configs/common/zsh/common.zsh
sed -i '/^export FAST_WORK_DIR=/d' configs/common/zsh/common.zsh
sed -i 's#"\$ZSH_PLUGINS/zsh-completions/src"#"$ZSH_COMPLETIONS_FPATH"#' configs/common/zsh/common.zsh
sed -i 's#"\$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"#"$ZSH_PLUGIN_FZF_TAB"#' configs/common/zsh/common.zsh
sed -i 's#"\$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"#"$ZSH_PLUGIN_FSH"#' configs/common/zsh/common.zsh
sed -i 's#/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh#$ZSH_PLUGIN_AUTOSUGGEST#' configs/common/zsh/common.zsh
grep -nE 'ZSH_PLUGIN_|ZSH_COMPLETIONS_FPATH|ZSH_PLUGINS|FAST_WORK_DIR' configs/common/zsh/common.zsh
```
Expected from grep: the three `source "$ZSH_PLUGIN_*"` lines and the `$ZSH_COMPLETIONS_FPATH`
fpath line present; NO bare `ZSH_PLUGINS=` or `FAST_WORK_DIR=` definitions remain.

- [ ] **Step 6: Distribute the zsh pieces and verify a fresh shell loads cleanly**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --force 2>&1 | grep -E 'zsh|os.zsh|common.zsh|.zshrc'
zsh -i -c '
  echo "EDITOR=$EDITOR"; alias ls;
  whence -w prj _accept_suggestion_to_slash fzf-tab-complete;
  echo "fsh theme=$FAST_THEME_NAME work_dir=$FAST_WORK_DIR";
  bindkey "^U"; bindkey "^I";
  whence z >/dev/null && echo "zoxide ok"; whence starship >/dev/null && echo "starship ok"
' 2>&1 | grep -v fallback
```
Expected: no errors; `EDITOR=nvim`; `ls=eza`; prj/widgets/fzf-tab-complete are functions;
`FAST_THEME_NAME=tokyodark`, `FAST_WORK_DIR=/home/yuy/.config/fsh`; `^U`=kill-whole-line;
`^I`=_accept_suggestion_to_slash; zoxide + starship ok.

- [ ] **Step 7: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add configs/common/zsh configs/linux/zsh configs/macos/zsh
git commit -m "refactor: split zsh into common.zsh + per-OS os.zsh + entrypoint"
```

---

### Task 6: Split ghostty (entrypoint + config-base + linux config-os + mac config-os)

**Files:**
- Create: `configs/common/ghostty/config`, `configs/common/ghostty/config-base`,
  `configs/linux/ghostty/config-os`, `configs/macos/ghostty/config-os`
- Backup: `~/.config/ghostty/config.pre-restructure`

- [ ] **Step 1: Back up live ghostty config**

```bash
cp ~/.config/ghostty/config ~/.config/ghostty/config.pre-restructure
```

- [ ] **Step 2: Write the entrypoint `configs/common/ghostty/config`**

```ini
# ~/.config/ghostty/config — entrypoint. Base first, then OS overrides.
config-file = config-base
config-file = config-os
```

- [ ] **Step 3: Write `configs/common/ghostty/config-base`** (shared content from the current live config)

```ini
# ---- Shell ----  (command is set per-OS in config-os)

# ---- Title / cursor ----
title = "terminal"
shell-integration-features = no-cursor
cursor-style = block_hollow
cursor-style-blink = true

# ---- Font ----
font-family = "JetBrainsMonoNL Nerd Font Mono"
font-size = 11

# ---- Theme ----
theme = "TokyoNight Storm"
background-opacity = 0.98

# ---- Experimental Vim Mode (entry key set per-OS in config-os) ----
keybind = vim/
keybind = vim/j=scroll_page_lines:1
keybind = vim/k=scroll_page_lines:-1
keybind = vim/ctrl+d=scroll_page_down
keybind = vim/ctrl+u=scroll_page_up
keybind = vim/g>g=scroll_to_top
keybind = vim/shift+g=scroll_to_bottom
keybind = vim/slash=start_search
keybind = vim/n=navigate_search:next
keybind = vim/v=copy_to_clipboard
keybind = vim/y=copy_to_clipboard
keybind = vim/shift+semicolon=toggle_command_palette
keybind = vim/escape=deactivate_key_table
keybind = vim/q=deactivate_key_table
keybind = vim/i=deactivate_key_table
keybind = vim/catch_all=ignore
```

- [ ] **Step 4: Write `configs/linux/ghostty/config-os`**

```ini
# linux/ghostty/config-os — Linux-only overrides (loaded after config-base).
command = /usr/bin/zsh
clipboard-read = allow
keybind = ctrl+shift+r=reload_config
keybind = ctrl+v=activate_key_table:vim
```

- [ ] **Step 5: Write `configs/macos/ghostty/config-os`** (derived from the pre-restructure mac ghostty config; unverified here)

```ini
# macos/ghostty/config-os — macOS-only overrides (loaded after config-base).
command = /bin/zsh
macos-titlebar-style = tabs
keybind = global:alt+space=new_window
keybind = alt+v=activate_key_table:vim
```

> Note for implementer: confirm the mac titlebar/keybind lines against the user's real Mac config
> when next on macOS (this machine cannot verify them). The vim entry on mac is alt+v (its original).

- [ ] **Step 6: Distribute + validate ghostty config parses, then reload daemon**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --force 2>&1 | grep -i ghostty
ghostty +show-config 2>/dev/null | grep -E 'theme|cursor-style|clipboard-read|ctrl\+v|config-file' | head
GPID=$(pgrep -x ghostty | head -1); [[ -n "$GPID" ]] && kill -USR2 "$GPID" && echo "reloaded $GPID"
```
Expected: distribute writes `config`, `config-base`, `config-os`; `+show-config` shows the merged
result (theme TokyoNight Storm, hollow cursor, clipboard-read=allow, ctrl+v vim); daemon reloaded.

- [ ] **Step 7: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add configs/common/ghostty configs/linux/ghostty configs/macos/ghostty
git commit -m "refactor: split ghostty into config-base + per-OS config-os + entrypoint"
```

---

### Task 7: Split git (entrypoint + common.gitconfig + linux signing + mac signing)

**Files:**
- Create: `configs/common/git/gitconfig`, `configs/common/git/common.gitconfig`,
  `configs/linux/git/signing`, `configs/macos/git/signing`
- Backup: `~/.gitconfig.pre-restructure`

- [ ] **Step 1: Back up live gitconfig**

```bash
cp ~/.gitconfig ~/.gitconfig.pre-restructure
```

- [ ] **Step 2: Write the entrypoint `configs/common/git/gitconfig`**

```ini
[include]
	path = ~/.config/git/common.gitconfig
[include]
	path = ~/.config/git/signing
```

- [ ] **Step 3: Write `configs/common/git/common.gitconfig`**

```ini
[user]
	name = Yuriy Y.
	email = 30913292+yurchenkoy@users.noreply.github.com
[core]
	editor = nvim
[init]
	defaultBranch = main
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
```

- [ ] **Step 4: Write `configs/linux/git/signing`**

```ini
[user]
	signingkey = /home/yuy/.ssh/git_signing_ed25519.pub
[gpg]
	format = ssh
[gpg "ssh"]
	allowedSignersFile = /home/yuy/.config/git/allowed_signers
[commit]
	gpgsign = true
[tag]
	gpgsign = true
```

> Note: keeping `signingkey` at the current `~/.ssh/...pub` path (where the key already works via
> the agent). If the user later moves the key into `secrets/`, update this one line to that path.

- [ ] **Step 5: Write `configs/macos/git/signing`** (GPG; from the pre-restructure mac gitconfig; unverified here)

```ini
[user]
	signingkey = 5AAD262109789ACC
[gpg]
	format = openpgp
	program = /opt/homebrew/bin/gpg
[commit]
	gpgsign = true
[tag]
	gpgsign = true
```

> Note: the mac GPG key id `5AAD262109789ACC` is carried from the old mac `.gitconfig`. Confirm/
> rotate on the Mac if desired.

- [ ] **Step 6: Distribute + verify signing still works end-to-end**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --force 2>&1 | grep -E 'gitconfig|common.gitconfig|signing'
export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
git config --get user.email; git config --get gpg.format; git config --get commit.gpgsign
R=$(mktemp -d); git -C "$R" init -q && git -C "$R" commit --allow-empty -m sigtest -q && git -C "$R" log --show-signature -1 | head -2; rm -rf "$R"
```
Expected: email + `gpg.format=ssh` + `commit.gpgsign=true` resolve through the includes; the
throwaway commit shows `Good "git" signature`.

- [ ] **Step 7: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add configs/common/git configs/linux/git configs/macos/git
git commit -m "refactor: split git into common.gitconfig + per-OS signing + entrypoint"
```

---

### Task 8: Seed Linux-only configs (xremap, hypr, environment.d)

**Files:**
- Create from live: `configs/linux/xremap/config.yml`, `configs/linux/hypr/hyprland.conf`,
  `configs/linux/environment.d/ssh-agent.conf`

- [ ] **Step 1: Collect the linux-only live configs into the repo**

```bash
cd /home/yuy/Documents/DotFiles
cp ~/.config/xremap/config.yml configs/linux/xremap/config.yml
cp ~/.config/hypr/hyprland.conf configs/linux/hypr/hyprland.conf
cp ~/.config/environment.d/ssh-agent.conf configs/linux/environment.d/ssh-agent.conf
```

- [ ] **Step 2: Verify distribute round-trips them as up-to-date**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --dry-run --force 2>&1 | grep -E 'xremap|hypr|environmentd'
```
Expected: `up to date: xremap`, `up to date: hypr`, `up to date: environmentd`.

- [ ] **Step 3: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add configs/linux/xremap configs/linux/hypr configs/linux/environment.d
git commit -m "feat: track linux-only configs (xremap, hyprland, environment.d)"
```

---

### Task 9: Reorganize mac-only configs + remove old layout

**Files:**
- Move: `configs/karabiner` → `configs/macos/karabiner`; `configs/aerospace` →
  `configs/macos/aerospace`; `configs/alfred` → `configs/macos/alfred`
- Delete: now-empty old `configs/{zsh,ghostty,git}` dirs

- [ ] **Step 1: git mv the mac-only configs**

```bash
cd /home/yuy/Documents/DotFiles
git mv configs/karabiner/karabiner.json configs/macos/karabiner/karabiner.json
git mv configs/aerospace/aerospace.toml configs/macos/aerospace/aerospace.toml
rsync -a configs/alfred/ configs/macos/alfred/ && git rm -r --quiet configs/alfred && git add configs/macos/alfred
```

- [ ] **Step 2: Remove the old top-level config dirs left from the mac layout**

```bash
cd /home/yuy/Documents/DotFiles
git rm -r --quiet configs/zsh configs/ghostty configs/git 2>/dev/null || true
rmdir configs/karabiner configs/aerospace 2>/dev/null || true
find configs -maxdepth 1 -type d | sort
```
Expected: only `configs`, `configs/common`, `configs/macos`, `configs/linux` remain.

- [ ] **Step 3: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add -A
git commit -m "refactor: move mac-only configs to configs/macos; drop old layout"
```

---

### Task 10: Move Brewfile + write linux-packages.md

**Files:**
- Move: `Brewfile` → `packages/Brewfile`
- Create: `packages/linux-packages.md`
- Delete: old `Packages` file

- [ ] **Step 1: Relocate the Brewfile and remove the informal Packages list**

```bash
cd /home/yuy/Documents/DotFiles
git mv Brewfile packages/Brewfile
rm -f Packages   # untracked in this repo — plain rm, not git rm
```

- [ ] **Step 2: Write `packages/linux-packages.md`** (seeded from the migration plan's mapping table)

```markdown
# Linux packages (source of truth — install by hand)

No runnable installer: package names/availability vary by distro. Below is the logical list and
how each was obtained on Fedora 44. Adapt per distro.

| Tool | How (Fedora 44) | Notes |
|---|---|---|
| neovim | `dnf install neovim` | |
| eza | `dnf install eza` | |
| fd | `dnf install fd-find` | binary is `fd` |
| fzf | `dnf install fzf` | |
| ripgrep | `dnf install ripgrep` | usually preinstalled |
| zoxide | `dnf install zoxide` | |
| gh | `dnf install gh` | |
| tree | `dnf install tree` | |
| git / git-lfs | `dnf install git git-lfs` | |
| node | `dnf install nodejs24 nodejs24-npm nodejs24-bin` | versioned package |
| dotnet | `dnf install dotnet-sdk-10.0` | v10 (not 8) |
| starship | COPR `atim/starship` then `dnf install starship` | not in base repos |
| zsh-autosuggestions | `dnf install zsh-autosuggestions` | `/usr/share/...` |
| zsh-completions | git clone → `~/.local/share/zsh/plugins/zsh-completions` | |
| fzf-tab | git clone → `~/.local/share/zsh/plugins/fzf-tab` | |
| fast-syntax-highlighting | git clone → `~/.local/share/zsh/plugins/fast-syntax-highlighting` | |
| Nerd Fonts | manual → `~/.local/share/fonts/` (JetBrainsMono NL + CaskaydiaCove) | `fc-cache -f` |
| ghostty | `dnf install ghostty` | |
| wl-clipboard | `dnf install wl-clipboard` | nvim system clipboard |
| keepassxc | `dnf install keepassxc` | SSH agent for git signing |
| xremap | prebuilt binary → `/usr/local/bin/xremap` | not packaged |
| hyprland + waybar + mako + hypridle + hyprpaper + wofi | `dnf install` | compositor stack |
| greetd + tuigreet | `dnf install greetd tuigreet` | login |

Skipped vs mac: python@3.11 (system python newer), spotify, caffeine (→ hypridle).
```

- [ ] **Step 3: Verify + commit**

```bash
cd /home/yuy/Documents/DotFiles
test -f packages/Brewfile && test -f packages/linux-packages.md && ! test -f Packages && echo OK
git add -A
git commit -m "refactor: packages/ with Brewfile + linux-packages.md"
```

---

### Task 11: Universal setup.sh

**Files:**
- Modify (rewrite): `setup.sh`

- [ ] **Step 1: Rewrite `setup.sh`**

```zsh
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
```

- [ ] **Step 2: Verify setup runs and re-symlinks scripts**

Run:
```bash
cd /home/yuy/Documents/DotFiles
zsh setup.sh 2>&1 | head -30
ls -l ~/.local/bin/dotfiles-collect ~/.local/bin/dotfiles-distribute | grep -- '->'
```
Expected: header `($(uname)→linux)`; symlinks (re)created pointing into the repo; the Linux
bootstrap section prints; no crash. (Plugin clones already exist → skipped.)

- [ ] **Step 3: Commit**

```bash
cd /home/yuy/Documents/DotFiles
git add setup.sh
git commit -m "feat: universal OS-detecting setup.sh"
```

---

### Task 12: README + final verification

**Files:**
- Modify (rewrite): `README.md`
- Optional: archive `LINUX_MIGRATION_PLAN.md`

- [ ] **Step 1: Rewrite `README.md`** with the structure below (fill the tables/commands verbatim)

````markdown
# DotFiles

Cross-platform dotfiles (macOS + Linux) managed with two copy-based scripts and an OS-aware
config-map. One repo provisions either machine after a reinstall or on new hardware.

## Managed configs

| Tool | OS | Live path |
|---|---|---|
| starship / fsh / nvim | both | `~/.config/...` (common) |
| zsh | both | `~/.zshrc` → sources `~/.config/zsh/{os,common}.zsh` |
| ghostty | both | mac: `~/Library/Application Support/com.mitchellh.ghostty/`, linux: `~/.config/ghostty/` |
| git | both | `~/.gitconfig` → includes `~/.config/git/{common.gitconfig,signing}` |
| karabiner / aerospace / alfred | macOS | `~/.config/...`, `~/Library/...` |
| xremap / hyprland / environment.d | Linux | `~/.config/...` |

## First-time setup — macOS
1. Install Homebrew.
2. `git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles && cd ~/Documents/DotFiles`
3. `./setup.sh`
4. `brew bundle --file=packages/Brewfile`
5. `dotfiles-distribute`
6. `chmod go-w "$(brew --prefix)/share" "$(brew --prefix)/share/zsh-completions"`
7. Place your GPG signing key (see `secrets/signing.template`).

## First-time setup — Linux
1. `git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles && cd ~/Documents/DotFiles`
2. Install packages per `packages/linux-packages.md`.
3. `./setup.sh` (symlinks scripts, clones zsh plugins, enables ssh-agent, prints manual steps).
4. `dotfiles-distribute`
5. `fast-theme XDG:tokyodark` (regenerates the fsh theme cache — only `tokyodark.ini` is tracked).
6. Finish the printed privileged/manual steps (xremap binary, greetd, KeePassXC, GitHub key).
7. Place your SSH signing key (see `secrets/signing.template`) + load it via KeePassXC.

## Daily workflow
```
dotfiles-collect        # edit live → save to repo (OS-filtered, diff + confirm)
git add -A && git commit -m 'update configs' && git push
dotfiles-distribute     # on the other machine
```

## Commands
| Command | What it does |
|---|---|
| `dotfiles-collect [--dry-run|--force]` | live → repo |
| `dotfiles-distribute [--dry-run|--force]` | repo → live |

## Adding a new config
Add one record to `DOTFILES_RECORDS` in `scripts/lib/config-map.zsh`
(`label|applies|type|repo_path|mac_live|linux_live`), then run `dotfiles-collect`.

## Refreshing the Brewfile (macOS)
`brew bundle dump --force --file=packages/Brewfile`
````

- [ ] **Step 2: Final full verification on this (Linux) machine**

Run:
```bash
cd /home/yuy/Documents/DotFiles
DOTFILES_DIR="$PWD" zsh scripts/dotfiles-distribute --dry-run --force 2>&1 | grep -vE 'up to date' | head
zsh -i -c 'echo shell-ok' 2>&1 | grep -v fallback | tail -1
export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
R=$(mktemp -d); git -C "$R" init -q && git -C "$R" commit --allow-empty -m v -q && git -C "$R" log --show-signature -1 | grep -i 'good.*signature'; rm -rf "$R"
```
Expected: distribute reports everything up to date (no `~`/`+` lines for linux/common records);
`shell-ok`; `Good "git" signature`.

- [ ] **Step 3: Archive the migration plan (optional) and commit**

```bash
cd /home/yuy/Documents/DotFiles
mkdir -p docs/archive && mv -f LINUX_MIGRATION_PLAN.md docs/archive/ 2>/dev/null || true   # untracked → plain mv
git add -A
git commit -m "docs: cross-platform README; archive migration plan"
```

- [ ] **Step 4: Clean up backups (after you're satisfied)**

```bash
rm -f ~/.zshrc.pre-restructure ~/.config/ghostty/config.pre-restructure ~/.gitconfig.pre-restructure
```

---

## Self-Review

**Spec coverage:**
- §3 layout → Tasks 1,4–10. §4 divergent mechanism → Tasks 5–7 (native includes; zsh os-first
  ordering noted in Global Constraints). §5 classification → Tasks 4–9. §6 secrets → Task 1
  (.gitignore allow-list, template) + git signing fragments reference keys (Task 7). §7 OS-aware
  map → Tasks 2–3. §8 setup.sh universal → Task 11. §9 README → Task 12. §10 initial seed →
  Tasks 4–9. §11 non-goals respected (no symlink/stow; single linux list; deploy-datahub
  untouched). §12 risks → backups per split task + mac-unverified notes.
- Gap check: `deploy-datahub` intentionally untouched (no task — correct). `allowed_signers`
  file is referenced by `configs/linux/git/signing` but is machine-local (already at
  `~/.config/git/allowed_signers`); it is NOT in the map (treated like a secret-adjacent local
  file). Implementer note: it persists across distribute since distribute never deletes it.

**Placeholder scan:** No TBD/TODO. Large `common.zsh` is specified as exact edits to a real input
file (the live `.zshrc`), not invented. Mac fragments carried verbatim from the existing repo
mac configs with explicit "verify on Mac" notes.

**Type/name consistency:** `df_os`/`df_each`/`DOTFILES_RECORDS` defined in Task 2, consumed in
Tasks 3 & 11. `ZSH_PLUGIN_FZF_TAB`/`ZSH_PLUGIN_FSH`/`ZSH_PLUGIN_AUTOSUGGEST`/
`ZSH_COMPLETIONS_FPATH` defined in os.zsh (Task 5 steps 3–4) and consumed in common.zsh (Task 5
step 5) — names match. Record `label`s in Task 2 match the grep filters used in verification steps.
```
