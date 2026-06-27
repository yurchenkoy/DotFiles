# DotFiles repo restructure — macOS + Linux coexistence

**Date:** 2026-06-27
**Status:** Design approved (pending written-spec review)
**Goal:** Restructure the DotFiles repo so one repo cleanly provisions both a macOS machine
and a Linux (currently Fedora 44 + Hyprland) machine, enabling quick setup after an OS
reinstall or on new hardware — without the two platforms' configs drifting apart.

---

## 1. Context

The repo currently targets macOS only. Live Linux configs were built this session and exist
only on the live machine (`~/.config/...`), not yet in the repo. The existing machinery is a
copy-based sync system:

- `scripts/dotfiles-collect` — copy live configs → repo (with fzf selection + diff preview + confirm).
- `scripts/dotfiles-distribute` — copy repo configs → live locations (same UX).
- Both share a config-map of four parallel arrays (`LABELS`/`SOURCES`/`DESTINATIONS`/`TYPES`)
  hardcoded to **macOS** live paths.
- `setup.sh` — symlinks scripts into `~/.local/bin`, cleans stale links. Mostly OS-agnostic.
- `scripts/deploy-datahub` — a work script (triggers a GitHub deploy workflow). macOS, outdated.
- `Brewfile` — macOS package manifest. `Packages` — an informal list (to be superseded).
- `README.md` — macOS only.

This design **extends** that copy-based system (it is well-built and the user likes its UX);
it does **not** switch to a symlink/stow model.

---

## 2. Decisions (settled during brainstorming)

1. **Layout:** `configs/{common,macos,linux}/` + `packages/` + `secrets/` + `scripts/`.
2. **Divergent files** (present on both OSes with different content): **base + per-OS fragment**,
   wired with each tool's **native include** — chosen to prevent functional drift without the
   clutter of one-file-with-conditionals. Applies to exactly **zsh, git, ghostty**.
3. **Entrypoints are uniform pure-include files** and are themselves *common* (identical on both
   machines). Only the `os` fragment differs per OS.
4. **Secrets:** a gitignored `secrets/` folder holds the real key material + a tracked template.
   The collect/distribute scripts **never touch `secrets/`** (so they cannot leak a key); keys
   are placed manually per machine, guided by the template + README. gitconfig's per-OS signing
   fragment (tracked, non-secret) references `secrets/`.
5. **Packages:** `Brewfile` stays for mac (runnable). Linux gets a single annotated
   `linux-packages.md` (source-of-truth list; **no runnable installer** — install by hand).
6. **setup.sh:** a single **universal** script that detects the OS and does the right thing.
7. **deploy-datahub:** kept macOS-only, **untouched**.
8. **README:** a **macOS** section and a **Linux** section (no Windows).

---

## 3. Directory layout

```
DotFiles/
├── configs/
│   ├── common/                       # identical on both OSes (single source of truth)
│   │   ├── starship/starship.toml
│   │   ├── fsh/tokyodark.ini
│   │   ├── nvim/…                     (whole LazyVim tree)
│   │   ├── zsh/
│   │   │   ├── zshrc                  # entrypoint: source common.zsh; source os.zsh
│   │   │   └── common.zsh             # shared bulk (LS_COLORS, fzf-tab, prj, widgets, zoxide, starship…)
│   │   ├── ghostty/
│   │   │   ├── config                 # entrypoint: config-file=config-base; config-file=config-os
│   │   │   └── config-base            # shared theme/font/cursor/opacity/clipboard/vim-table
│   │   └── git/
│   │       ├── gitconfig              # entrypoint: [include] common.gitconfig; [include] signing
│   │       └── common.gitconfig       # name, email, editor, init.defaultBranch, lfs
│   ├── macos/                         # mac-only
│   │   ├── zsh/os.zsh                 # brew paths, /opt/homebrew plugin sources, etc.
│   │   ├── ghostty/config-os          # mac titlebar, super binds, command=/bin/zsh
│   │   ├── git/signing                # gpg.format=openpgp, program, signingkey=<GPG id>, gpgsign
│   │   ├── karabiner/karabiner.json
│   │   ├── aerospace/aerospace.toml
│   │   └── alfred/Alfred.alfredpreferences
│   └── linux/                         # linux-only
│       ├── zsh/os.zsh                 # dnf + /usr/share + ~/.local/share plugins, FAST_WORK_DIR
│       ├── ghostty/config-os          # clipboard-read=allow, ctrl+shift+r, ctrl+v vim, command=/usr/bin/zsh
│       ├── git/signing                # gpg.format=ssh, allowedSignersFile, signingkey=secrets/…pub, gpgsign
│       ├── xremap/config.yml
│       ├── hypr/hyprland.conf
│       ├── environment.d/ssh-agent.conf
│       └── (waybar/ mako/ hypridle/ … added later during ricing — step 10)
├── packages/
│   ├── Brewfile                       # mac (runnable: brew bundle)
│   └── linux-packages.md              # annotated source-of-truth list (manual install)
├── secrets/                           # gitignored — real keys live here
│   ├── .gitignore                     # ignore everything except the template (see §6)
│   └── signing.template               # tracked example to copy + fill in
├── scripts/
│   ├── dotfiles-collect               # OS-aware (see §7)
│   ├── dotfiles-distribute            # OS-aware (see §7)
│   └── deploy-datahub                 # mac, untouched
├── setup.sh                           # universal, OS-detecting (see §8)
├── README.md                          # mac section + linux section (see §9)
└── docs/superpowers/specs/…           # this document
```

Notes:
- The three ghostty files (`config`, `config-base`, `config-os`) all live in the ghostty config
  dir on each machine, so ghostty's relative `config-file` resolution works.
- Anything system-level/privileged (e.g. `/etc/greetd/`, the `/usr/local/bin/xremap` binary,
  systemd *user* units) is **not** in the copy-map; it is handled/printed by `setup.sh` and the
  README (see §8). `environment.d/ssh-agent.conf` is user-space so it IS managed.

---

## 4. Divergent-file mechanism (base + fragment via native includes)

For each of the three dual-OS divergent configs, the file at the app's default path is a
**common, pure-include entrypoint**; content is split into a **common fragment** and an
**OS fragment**; the OS fragment is loaded *after* the common one so it can override.

| App | Entrypoint (common, default path) | Common fragment | OS fragment |
|---|---|---|---|
| zsh | `~/.zshrc` → `source ~/.config/zsh/common.zsh` then `source ~/.config/zsh/os.zsh` | `~/.config/zsh/common.zsh` | `~/.config/zsh/os.zsh` |
| ghostty | `~/.config/ghostty/config` → `config-file = config-base` then `config-file = config-os` | `~/.config/ghostty/config-base` | `~/.config/ghostty/config-os` |
| git | `~/.gitconfig` → `[include] path = ~/.config/git/common.gitconfig` then `[include] path = ~/.config/git/signing` | `~/.config/git/common.gitconfig` | `~/.config/git/signing` |

Round-trip property: because includes keep the files **separate on disk at runtime**, every live
file maps 1:1 to a repo file. `dotfiles-collect` copies each live file back to its repo home with
no merge/split logic. The "common vs OS-specific" decision is made by the user *at edit time* by
choosing which fragment to edit; the collect diff preview shows which files changed.

**Escape hatch:** a future config that is dual-OS + divergent + lacks an include directive falls
back to two full separate copies (a `macos/` row and a `linux/` row, no `common` row). Nothing
today needs this.

---

## 5. Config classification

| Config | Class | Mechanism |
|---|---|---|
| starship | common | single file |
| fsh (tokyodark.ini) | common | single file |
| nvim (LazyVim) | common | single dir |
| zsh | dual-OS divergent | entrypoint + common.zsh + os.zsh |
| ghostty | dual-OS divergent | entrypoint + config-base + config-os |
| git | dual-OS divergent | entrypoint + common.gitconfig + signing |
| karabiner | mac-only | single file |
| aerospace | mac-only | single file |
| alfred | mac-only | single dir |
| xremap | linux-only | single file |
| hyprland | linux-only | single file |
| environment.d/ssh-agent | linux-only | single file |
| waybar / mako / hypridle | linux-only (future) | single file/dir, added during ricing |

Keybinding stacks have **zero overlap** across OSes (karabiner+aerospace vs xremap+hyprland), so
they are always OS-folders, never common.

---

## 6. Secrets

- `secrets/.gitignore` ignores **everything** and allow-lists only the template:
  ```
  *
  !.gitignore
  !signing.template
  ```
- `secrets/signing.template` documents the per-machine key layout and how to populate it.
- **Linux:** the private signing key lives in KeePassXC (loaded into the ssh-agent on unlock);
  `secrets/` holds the keypair files the user chooses to keep there, and the tracked
  `configs/linux/git/signing` fragment sets `user.signingkey` to a `secrets/…pub` path (plus
  `gpg.format=ssh`, `gpg.ssh.allowedSignersFile`, `commit.gpgsign=true`, `tag.gpgsign=true`).
- **macOS:** signing uses GPG; `configs/macos/git/signing` sets `gpg.format=openpgp`,
  `gpg.program`, `user.signingkey=<GPG key id>`, `commit.gpgsign=true`. The GPG key lives in the
  GPG keyring; an optional backup may sit in `secrets/`.
- If the referenced key is absent, signing fails and the commit is blocked (fail-closed — the
  user's explicit preference: never produce an accidental unsigned commit).
- The scripts deploy the **tracked, non-secret** `signing` fragment; they never read or write
  `secrets/`.

---

## 7. Scripts — OS-aware config-map

Replace the four parallel arrays with one record list, shared by collect & distribute. Record
format (pipe-delimited):

```
label | applies | type | repo_path | mac_live | linux_live
```

- `applies` ∈ `both | mac | linux`
- `type` ∈ `file | dir`
- `repo_path` — relative to repo root
- `mac_live` / `linux_live` — absolute live path (may use `$HOME`); `-` when N/A

Behavior:
- Detect OS once (`uname` → `mac` or `linux`).
- Iterate records; **skip** any whose `applies` excludes the current OS.
- Use the current OS's live-path column (`mac_live` or `linux_live`).
- Everything else (fzf multi-select menu, dry-run, force, per-item diff preview, confirm, dir
  rsync vs file cp, Brewfile handling) is preserved. Brewfile collect/dump only runs on mac.
- Repo discovery: keep `$DOTFILES_DIR` override; the `-f "$REPO_DIR/setup.sh"` sentinel check
  still holds.

Representative record set (current; `waybar`/`mako`/`hypridle` appended during ricing). Mac
ghostty live dir = `$HOME/Library/Application Support/com.mitchellh.ghostty`:

```
# common entrypoints (pure includes)
zshrc        | both  | file | configs/common/zsh/zshrc            | $HOME/.zshrc                          | $HOME/.zshrc
ghostty      | both  | file | configs/common/ghostty/config       | <mac-ghostty>/config                  | $HOME/.config/ghostty/config
gitconfig    | both  | file | configs/common/git/gitconfig        | $HOME/.gitconfig                      | $HOME/.gitconfig
# common fragments / single files
zsh-common   | both  | file | configs/common/zsh/common.zsh       | $HOME/.config/zsh/common.zsh          | $HOME/.config/zsh/common.zsh
ghostty-base | both  | file | configs/common/ghostty/config-base  | <mac-ghostty>/config-base             | $HOME/.config/ghostty/config-base
git-common   | both  | file | configs/common/git/common.gitconfig | $HOME/.config/git/common.gitconfig    | $HOME/.config/git/common.gitconfig
starship     | both  | file | configs/common/starship/starship.toml | $HOME/.config/starship.toml         | $HOME/.config/starship.toml
fsh          | both  | dir  | configs/common/fsh                  | $HOME/.config/fsh                     | $HOME/.config/fsh
nvim         | both  | dir  | configs/common/nvim                 | $HOME/.config/nvim                    | $HOME/.config/nvim
# os fragments
zsh-os       | mac   | file | configs/macos/zsh/os.zsh            | $HOME/.config/zsh/os.zsh              | -
zsh-os       | linux | file | configs/linux/zsh/os.zsh            | -                                     | $HOME/.config/zsh/os.zsh
ghostty-os   | mac   | file | configs/macos/ghostty/config-os     | <mac-ghostty>/config-os               | -
ghostty-os   | linux | file | configs/linux/ghostty/config-os     | -                                     | $HOME/.config/ghostty/config-os
git-signing  | mac   | file | configs/macos/git/signing           | $HOME/.config/git/signing             | -
git-signing  | linux | file | configs/linux/git/signing           | -                                     | $HOME/.config/git/signing
# mac-only
karabiner    | mac   | file | configs/macos/karabiner/karabiner.json | $HOME/.config/karabiner/karabiner.json | -
aerospace    | mac   | file | configs/macos/aerospace/aerospace.toml | $HOME/.config/aerospace/aerospace.toml | -
alfred       | mac   | dir  | configs/macos/alfred/Alfred.alfredpreferences | $HOME/Library/Application Support/Alfred/Alfred.alfredpreferences | -
# linux-only
xremap       | linux | file | configs/linux/xremap/config.yml     | -                                     | $HOME/.config/xremap/config.yml
hypr         | linux | file | configs/linux/hypr/hyprland.conf    | -                                     | $HOME/.config/hypr/hyprland.conf
environmentd | linux | file | configs/linux/environment.d/ssh-agent.conf | -                              | $HOME/.config/environment.d/ssh-agent.conf
```

---

## 8. setup.sh (universal)

A single OS-detecting script. Shared behavior on both OSes:
- Make scripts executable; symlink `scripts/*` into `~/.local/bin`; clean stale symlinks
  (existing logic, kept).
- Offer to run `dotfiles-distribute`.

OS-specific behavior:
- **macOS:** print the Homebrew + `brew bundle` steps (or run if brew present), the
  `chmod go-w "$(brew --prefix)/share"` completions fix, and `fast-theme` note.
- **Linux:** automate the **unprivileged** parts — git-clone the zsh plugins into
  `~/.local/share/zsh/plugins/` (fzf-tab, zsh-completions, fast-syntax-highlighting), install the
  Nerd Fonts into `~/.local/share/fonts/`, `systemctl --user enable --now ssh-agent.service`,
  apply the fsh theme, run `dotfiles-distribute`. **Print** the privileged/manual steps it cannot
  safely do: `dnf` installs from `linux-packages.md`, greetd/tuigreet, the xremap binary install,
  KeePassXC SSH-agent setup, and the GitHub signing-key upload.

`deploy-datahub` is unchanged and remains mac-relevant only.

---

## 9. README

Top: one-paragraph purpose + the managed-config table (annotated with which OS each applies to).
Then two self-contained quick-setup sections:

- **macOS:** install Homebrew → clone → `./setup.sh` → `brew bundle` → `dotfiles-distribute` →
  completions chmod → place signing key in `secrets/`.
- **Linux:** clone → install packages per `packages/linux-packages.md` → `./setup.sh` (does the
  unprivileged bootstrap) → finish the printed privileged/manual steps → place signing key in
  `secrets/` + KeePassXC.

Plus the existing **Daily workflow** (collect → commit → push; distribute elsewhere), **Commands**
table, **Adding a new config** (now: add one record to the shared map), and package-refresh notes.

---

## 10. Migration / initial seed (implementation outline)

The repo must be populated from two sources without loss:
1. **Linux side (live, this machine):** split each divergent live config into common + os
   fragments + entrypoint, and copy single-file linux configs into `configs/linux/`.
   - `~/.zshrc` → `common.zsh` (shared bulk) + `linux/zsh/os.zsh` (dnf/plugin/path lines,
     `FAST_WORK_DIR`, dropped-python-alias delta) + `common/zsh/zshrc` (pure-source entrypoint).
   - ghostty live `config` → `config-base` (theme/font/cursor/opacity/clipboard/vim-table) +
     `linux/ghostty/config-os` (linux-only keys) + `common/ghostty/config` (pure-include entry).
   - `~/.gitconfig` → `common.gitconfig` (name/email/editor/init/lfs) + `linux/git/signing`
     (ssh signing) + `common/git/gitconfig` (pure-include entry).
   - Copy `xremap/config.yml`, `hypr/hyprland.conf`, `environment.d/ssh-agent.conf` to
     `configs/linux/`; `starship.toml`, `fsh/`, `nvim/` to `configs/common/`.
2. **macOS side (existing repo `configs/*`):** reclassify — move starship/fsh/nvim to `common/`;
   split the existing mac `.zshrc`/ghostty/`.gitconfig` into the **same common base** + a
   `macos/` os-fragment (the common base must be the shared intersection of mac & linux);
   move karabiner/aerospace/alfred to `macos/`.
3. **Verify:** the common base must produce a working shell/editor/terminal on **both** OSes.
   The **linux** side is fully testable now (`zsh -i -c …`, ghostty reload, `git log
   --show-signature`). The **macOS** side is verified by the user next time on the Mac — call this
   out as a known limitation.
4. Add `secrets/.gitignore` + template; write `linux-packages.md` (seed from the
   `LINUX_MIGRATION_PLAN.md` mapping table); rewrite scripts + setup.sh + README.
5. `LINUX_MIGRATION_PLAN.md` can be retired/archived once its content is absorbed.

This is a structural refactor of an existing working setup: the live Linux machine keeps working
throughout (distribute is only run to re-materialize the split files, which reproduce the current
behavior).

---

## 11. Out of scope / non-goals

- No switch to symlink/stow/chezmoi — the copy-based collect/distribute model is retained.
- No multi-distro package abstraction — single annotated linux list; per-distro adaptation is
  manual when/if a new distro is used.
- Waybar/mako/hypridle and other ricing configs are added later (step 10), via new map records.
- `deploy-datahub` is not adapted.

## 12. Risks

- **macOS base unverified now** (no Mac present) — mitigated by deriving the common base as the
  literal shared intersection and flagging it for user verification on next Mac use.
- **Splitting `.zshrc` incorrectly** could put an OS-specific line in `common.zsh` — mitigated by
  the collect diff preview and by the fail-closed nature of testing on linux immediately.
- **Secrets leak** if `.gitignore` is wrong — mitigated by the allow-list `.gitignore` and scripts
  never touching `secrets/`.
```
