# DotFiles

Cross-platform dotfiles (macOS + Linux) driven by an OS-aware config-map. Live config paths are
**symlinks into this repo**, so there is one copy of every file and a repo edit is live
immediately. One repo provisions either machine after a reinstall or on new hardware.

## Managed configs

| Tool | OS | Live path |
|---|---|---|
| starship / fsh / nvim | both | `~/.config/...` (common) |
| zsh | both | `~/.zshrc` → sources `~/.config/zsh/{os,common}.zsh` |
| ghostty | both | mac: `~/Library/Application Support/com.mitchellh.ghostty/`, linux: `~/.config/ghostty/` |
| git | both | `~/.gitconfig` → includes `~/.config/git/{common.gitconfig,signing}` |
| karabiner / aerospace / alfred | macOS | `~/.config/...`, `~/Library/...` |
| xremap / environment.d | Linux | `~/.config/...` |
| hypr / waybar / mako / fuzzel / wlogout | Linux | `~/.config/...` (desktop, see below) |

Every live path above is a symlink into this repo, except records marked `copy` in the map.

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
5. `scripts/theme-apply` — **required, not cosmetic.** It generates the color fragments every desktop config pulls in. Without it Hyprland does not start at all (`require("colors")` is a hard error when the file is missing), and Waybar, fuzzel and mako come up unthemed.
6. `fast-theme XDG:tokyodark` (regenerates the fsh theme cache — only `tokyodark.ini` is tracked).
7. Finish the printed privileged/manual steps (xremap binary, greetd, a polkit agent, Proton Pass, GitHub key).
8. Set up commit signing — see below.

## Commit signing
SSH signing on **both** macOS and Linux, with the private key in a Proton Pass vault served by its
SSH agent. Commits are always signed and are **blocked until this is set up** (fail-closed): the
repo tracks only the always-sign policy, and you create the per-machine
`~/.config/git/signing.local` yourself. Full walkthrough in `secrets/signing.template`.

Add the public key to GitHub as a **Signing** key — its own type; an Authentication key does not
make commits show as Verified.

If a commit fails with `No private key found for public key …`, Proton Pass is closed or its vault
is locked. The socket can exist while nothing listens on it. Unlock it; this recurs after reboots.

## Linux desktop (Hyprland — TokyoNight)
A coherent TokyoNight Storm desktop, all deployed by symlink. Components:
- **Theme generator** — `configs/linux/theme/tokyonight.conf` is the master palette; `scripts/theme-apply` templates each app's color fragment (Hyprland `colors.lua`, Waybar `colors.css`, hyprlock `hyprlock-colors.conf`, fuzzel `colors.ini`, mako `colors`). Change a hex once, re-run `theme-apply`, everything updates.
- **Waybar** — mac-menu-bar layout: workspaces + window title, centered clock w/ scrollable calendar, and right-side modules (volume, multi-device Bluetooth w/ battery, network, GPU temp, RAM, language switcher, notification bell, power). Icons need **Symbols Nerd Font** (the Mono variants squish glyphs); see packages list.
- **Wallpaper** — `swaybg`, started by `scripts/wallpaper-init`, which falls back to a solid palette colour when the slot is empty. The image is **not** tracked in this repo; back up `~/Pictures/Wallpapers/` yourself. A picker is planned against hyprpaper on Arch.
- **Power** — `wlogout` (Lock/Sleep/Reboot/Shutdown), bound to the Waybar power button and `Caps+Super+Esc`. Locking is manual only: there is no idle daemon, and the hyprlock config was removed pending a rebuild on Arch, so `hyprlock` currently runs unthemed.
- **Notifications** — `mako`, with per-source styling matched on app name (`notify-send -a <name>`). Right-click the Waybar bell for do-not-disturb, middle-click to clear.
- **Launcher** — `fuzzel` (`Super+Space`), also the dmenu front-end for `fz-*` wrapper scripts. Validate edits with `fuzzel --dmenu </dev/null`; it names any bad key.
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
Edit the config in this repo — it *is* the live file. Then:
```
git add -A && git commit -m 'update configs' && git push
```
`dotfiles-distribute` only needs re-running after adding a record, or on a fresh machine.

```
dotfiles-distribute              # link repo → live (idempotent; re-running is a no-op)
dotfiles-distribute --dry-run    # show what would change, touch nothing
dotfiles-distribute --force      # every record, no fzf picker, no confirmation
dotfiles-distribute --prune      # list symlinks into the repo that no record claims
dotfiles-collect                 # only `copy`-mode records (macOS Alfred) + the Brewfile
```
A real file or directory sitting where a symlink belongs is moved to `<path>.bak`, never deleted.

**Linked, not copied.** `copy` mode exists only for apps that save by writing a temp file and
renaming it over the target, which replaces the symlink with a regular file and silently detaches
the config from the repo. Alfred's preferences bundle is the one known case. If a tracked file ever
turns back into a real file after using an app's GUI, that app needs `copy` mode too.

**Generated files.** `theme-apply` writes its colour fragments next to the configs that include
them — which, with directory symlinks, means inside this repo. They are listed in `.gitignore`.

## Adding a new config
Add one record to `DOTFILES_RECORDS` in `scripts/lib/config-map.zsh`
(`label|applies|type|repo_path|mac_live|linux_live|mode`, where `mode` defaults to `link`), then
run `dotfiles-distribute`.

## Refreshing the Brewfile (macOS)
`brew bundle dump --force --file=packages/Brewfile`

Note this **overwrites** the file from what is currently installed, so a manually added entry
(e.g. `proton-pass`) disappears if that app is not installed on the machine doing the dump.
