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

## First time setup on a new machine

```zsh
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the repo
git clone <your-repo-url> ~/Documents/DotFiles

# 3. Run init (makes scripts executable + symlinks them to ~/.local/bin)
cd ~/Documents/DotFiles
./init.sh

# 4. Install all dependencies
brew bundle install

# 5. Apply configs
dsync-down
# 6. Give permisisons 
chmod go-w "$(brew --prefix)/share/zsh-completions"
chmod go-w "$(brew --prefix)/share"

#7. Update theme (optional)
fast-theme ~/.config/fsh/tokyodark.ini
```

## Daily workflow

```zsh
# After editing configs — save to repo
dsync-up
git diff                                     # review what changed
git add -A && git commit -m 'update configs'
git push

# On another machine — pull and apply
dsync-down
```

## Commands

| Command | What it does |
|---|---|
| `dsync-up` | Copy live configs into the repo |
| `dsync-up --dry-run` | Preview what would be copied, no writes |
| `dsync-down` | Pull, diff, confirm, then apply to live locations |
| `dsync-down --dry-run` | Preview incoming changes only, no writes |
| `dsync-down --force` | Apply without confirmation prompt |

## Adding a new config

Add one line to the `CONFIG_MAP` array near the top of both `bin/dsync-up`
and `bin/dsync-down`, following the existing format. Then run `dsync-up` to
seed it into the repo.

## Regenerating the Brewfile

```zsh
cd ~/Documents/DotFiles
brew bundle dump --force
git add Brewfile && git commit -m 'update Brewfile'
```
