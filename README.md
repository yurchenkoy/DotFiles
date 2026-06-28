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
7. Set up commit signing: create `~/.config/git/signing.local` with your key (see `secrets/signing.template`). Commits are always signed; until this file exists, commits are blocked (fail-closed).

## First-time setup — Linux
1. `git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles && cd ~/Documents/DotFiles`
2. Install packages per `packages/linux-packages.md`.
3. `./setup.sh` (symlinks scripts, clones zsh plugins, enables ssh-agent, prints manual steps).
4. `dotfiles-distribute`
5. `fast-theme XDG:tokyodark` (regenerates the fsh theme cache — only `tokyodark.ini` is tracked).
6. Finish the printed privileged/manual steps (xremap binary, greetd, KeePassXC, GitHub key).
7. Set up commit signing: create `~/.config/git/signing.local` with your key (see `secrets/signing.template`), load the key into KeePassXC/agent, and add the public key to GitHub as a Signing key. Commits are always signed; until this file exists, commits are blocked (fail-closed).

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

### tuigreet theme (privileged)

The login greeting is themed via greetd's config. Edit `/etc/greetd/config.toml` and add a
TokyoNight `--theme` string + greeting to the existing greeter `command`. IMPORTANT: keep the
existing `--cmd start-hyprland` (the session wrapper) and `--asterisks` flags — only ADD the
`--greeting`/`--theme` options:

    command = "tuigreet --time --remember --asterisks --greeting 'Welcome back' --theme 'border=blue;text=cyan;prompt=magenta;time=blue;action=blue;button=magenta;container=black;input=white' --cmd start-hyprland"

Then restart greetd: `sudo systemctl restart greetd` (this kills the current session — do it from a
TTY or on next reboot). Do NOT change `--cmd start-hyprland` to bare `Hyprland`: `start-hyprland`
is the wrapper that sets up the session environment.
