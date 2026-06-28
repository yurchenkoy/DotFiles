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
8. `allowed_signers` (`~/.config/git/allowed_signers`) is machine-local — create it for local signature verification (see `secrets/signing.template`).

## Daily workflow
```
dotfiles-collect        # edit live → save to repo (OS-filtered, diff + confirm)
git add -A && git commit -m 'update configs' && git push
dotfiles-distribute     # on the other machine
```

## Commands
| Command | What it does |
|---|---|
| `dotfiles-collect [--dry-run\|--force]` | live → repo |
| `dotfiles-distribute [--dry-run\|--force]` | repo → live |

## Adding a new config
Add one record to `DOTFILES_RECORDS` in `scripts/lib/config-map.zsh`
(`label|applies|type|repo_path|mac_live|linux_live`), then run `dotfiles-collect`.

## Refreshing the Brewfile (macOS)
`brew bundle dump --force --file=packages/Brewfile`
