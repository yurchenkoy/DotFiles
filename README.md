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
| xremap / environment.d | Linux | `~/.config/...` |
| hypr / waybar / swaync / wlogout / vicinae | Linux | `~/.config/...` (desktop, see below) |

The full list is `DOTFILES_RECORDS` in `scripts/lib/config-map.zsh` — that file is the source of
truth; this table is a summary.

## First-time setup — macOS
1. Install Homebrew.
2. `git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles && cd ~/Documents/DotFiles`
3. `./setup.sh`
4. `brew bundle --file=packages/Brewfile`
5. `dotfiles-distribute`
6. `chmod go-w "$(brew --prefix)/share" "$(brew --prefix)/share/zsh-completions"`
7. Set up commit signing — see below.

## First-time setup — Linux
1. `git clone https://github.com/yurchenkoy/DotFiles ~/Documents/DotFiles && cd ~/Documents/DotFiles`
2. Install packages per `packages/linux-packages.md`.
3. `./setup.sh` (symlinks scripts, clones zsh plugins, prints manual steps).
4. `dotfiles-distribute`
5. `scripts/theme-apply` — **required, not cosmetic.** It generates the color fragments every desktop config pulls in. Without it Hyprland does not start at all (`require("colors")` is a hard error when the file is missing), and Waybar, swaync and hyprlock come up unthemed.
6. `fast-theme XDG:tokyodark` (regenerates the fsh theme cache — only `tokyodark.ini` is tracked).
7. Finish the printed privileged/manual steps (xremap binary, greetd, Proton Pass, GitHub key).
8. Set up commit signing — see below.

## Commit signing
Commits are always signed, and are **blocked until this is set up** (fail-closed). Create
`~/.config/git/signing.local` with your key — see `secrets/signing.template`.

On Linux the private key lives in Proton Pass with its SSH agent enabled; add the public key to
GitHub as a **Signing** key (not just an Authentication key).

## Linux desktop (Hyprland — TokyoNight)
A coherent TokyoNight Storm desktop, all managed by collect/distribute. Components:
- **Theme generator** — `configs/linux/theme/tokyonight.conf` is the master palette; `scripts/theme-apply` templates each app's color fragment (Hyprland `colors.lua`, Waybar/swaync `colors.css`, hyprlock `hyprlock-colors.conf`, vicinae `tokyonight.toml`). Change a hex once, re-run `theme-apply`, everything updates.
- **Waybar** — mac-menu-bar layout: workspaces + window title, centered clock w/ scrollable calendar, and right-side modules (volume, multi-device Bluetooth w/ battery, network, GPU temp, RAM, language switcher, swaync bell, power). Icons need **Symbols Nerd Font** (the Mono variants squish glyphs); see packages list.
- **Wallpaper** — `swaybg` (hyprpaper is broken on Fedora's mixed Hyprland COPRs). Swap it with `scripts/set-wallpaper <image>`.
- **Power** — `hyprlock` (themed lock) + `wlogout` (Lock/Sleep/Reboot/Shutdown), bound to the Waybar power button and `Caps+Super+Esc`. Locking is manual only (no idle daemon).
- **Notifications** — `swaync` (history + do-not-disturb), replaces mako.
- **Launcher** — vicinae (`Super+Space`), replacing rofi/wofi/fuzzel. Runs as a user daemon; two of its settings are deliberate and easy to undo by accident — see Desktop notes in `packages/linux-packages.md`.
- **Screenshots** — `grim`/`slurp`/`swappy` (`Super+Shift+4` region, `Super+Shift+3` full → `~/Pictures/Screenshots` + clipboard).
- **Bluetooth labels** — edit `~/.config/waybar/bluetooth-rename.conf` (`MAC=Label`).

### tuigreet theme (privileged)

The login greeting is themed via greetd's config. Edit `/etc/greetd/config.toml` and add a
TokyoNight `--theme` string + greeting to the existing greeter `command`. IMPORTANT: keep the
existing `--cmd start-hyprland` (the session wrapper) and `--asterisks` flags — only ADD the
`--greeting`/`--theme` options:

    command = "tuigreet --time --remember --asterisks --greeting 'Welcome back' --theme 'border=blue;text=cyan;prompt=magenta;time=blue;action=blue;button=magenta;container=black;input=white' --cmd start-hyprland"

Then restart greetd: `sudo systemctl restart greetd` (this kills the current session — do it from a
TTY or on next reboot). Do NOT change `--cmd start-hyprland` to bare `Hyprland`: `start-hyprland`
is the wrapper that sets up the session environment.

## Daily workflow
```
dotfiles-collect        # live → repo (OS-filtered, diff + confirm)
git add -A && git commit -m 'update configs' && git push
dotfiles-distribute     # repo → live, on the other machine
```
Both take `--dry-run` (print the diff, change nothing) and `--force` (select **every** config,
skipping both the fzf picker and the confirmation prompt).

## Adding a new config
Add one record to `DOTFILES_RECORDS` in `scripts/lib/config-map.zsh`
(`label|applies|type|repo_path|mac_live|linux_live`), then run `dotfiles-collect`.

## Refreshing the Brewfile (macOS)
`brew bundle dump --force --file=packages/Brewfile`
