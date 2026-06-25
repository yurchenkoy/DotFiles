# DotFiles

Personal dotfiles for macOS. Managed with two simple scripts.

## Managed configs

| Tool | Live path |
|---|---|
| zsh | `~/.zshrc` |
| ghostty | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| lazyvim / nvim | `~/.config/nvim/` |
| starship | `~/.config/starship.toml` |
| fsh themes | `~/.config/fsh/` |
| alfred | `~/Library/Application Support/Alfred/Alfred.alfredpreferences` |
| git | `~/.gitconfig` |
| karabiner | `~/.config/karabiner/karabiner.json` |
| aerospace | `~/.config/aerospace/aerospace.toml` |

## First time setup on a new machine

```zsh
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the repo
git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles

# 3. Run setup (makes scripts executable, symlinks them to ~/.local/bin, cleans stale links)
cd ~/Documents/DotFiles
./setup.sh

# 4. Install all dependencies
brew bundle install

# 5. Apply configs
dotfiles-distribute

# 6. Give permissions
chmod go-w "$(brew --prefix)/share/zsh-completions"
chmod go-w "$(brew --prefix)/share"

# 7. Update theme (optional)
fast-theme ~/.config/fsh/tokyodark.ini
```

## Daily workflow

```zsh
# After editing configs — save to repo
dotfiles-collect
git diff                                     # review what changed
git add -A && git commit -m 'update configs'
git push

# On another machine — pull and apply
dotfiles-distribute
```

## Commands

| Command | What it does |
|---|---|
| `dotfiles-collect` | Select configs interactively, diff, confirm, then copy into repo |
| `dotfiles-collect --dry-run` | Show selection menu and preview, no writes |
| `dotfiles-collect --force` | Skip selection menu and confirmation — collect everything |
| `dotfiles-distribute` | Select configs interactively, diff, confirm, then apply to live locations |
| `dotfiles-distribute --dry-run` | Show selection menu and preview, no writes |
| `dotfiles-distribute --force` | Skip selection menu and confirmation — distribute everything |

## Adding a new config

Add one entry to the `LABELS`, `SOURCES`, `DESTINATIONS`, and `TYPES` arrays near the top of both
`scripts/dotfiles-collect` and `scripts/dotfiles-distribute`, following the existing format.
Then run `dotfiles-collect` to seed it into the repo.

## Regenerating the Brewfile

```zsh
cd ~/Documents/DotFiles
brew bundle dump --force
git add Brewfile && git commit -m 'update Brewfile'
```
