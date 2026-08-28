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
| Nerd Fonts | manual → `~/.local/share/fonts/` (JetBrainsMono NL + CaskaydiaCove **Mono**) | `fc-cache -f` |
| Symbols Nerd Font | manual → `~/.local/share/fonts/` from nerd-fonts `NerdFontsSymbolsOnly.zip` | full-size Waybar icons; the Mono variants squish glyphs into one cell |
| ghostty | `dnf install ghostty` | |
| wl-clipboard | `dnf install wl-clipboard` | nvim system clipboard |
| Proton Pass | download RPM from proton.me → `dnf install ./ProtonPass.rpm` | SSH agent for git signing (paid plan; not Pass Essentials) |
| xremap | prebuilt binary → `/usr/local/bin/xremap` | not packaged |
| hyprland + waybar + hyprlock | `dnf install` | compositor stack (mako dropped, see below) |
| swaybg | `dnf install swaybg` | wallpaper (replaces hyprpaper, which is broken on Fedora's mixed Hyprland COPRs — see note) |
| vicinae | `dnf copr enable scottames/vicinae` → `dnf install vicinae` | Super+Space launcher. Daemon; started by `exec-once = systemctl --user start vicinae` because `graphical-session.target` never activates without uwsm. See note below. |
| SwayNotificationCenter | `dnf install SwayNotificationCenter` | notifications + history panel (replaces mako) |
| wlogout | `dnf install wlogout` | power menu grid |
| grim + slurp + swappy | `dnf install grim slurp swappy` | screenshots + annotate |
| pavucontrol | `dnf install pavucontrol` | audio control (Waybar audio click) |
| upower | preinstalled | per-device Bluetooth battery in Waybar |
| greetd + tuigreet | `dnf install greetd tuigreet` | login |

Skipped vs mac: python@3.11 (system python newer), spotify, caffeine / hypridle (no idle management — declined).

**Launcher history.** rofi (hand-rolled `launcher.sh`), wofi and fuzzel were all removed in favour
of vicinae. rofi's script rebuilt a full `fd` scan of `$HOME` on every keypress and could only do
prefix matching in alphabetical order; fuzzel was trialled as the minimal-supply-chain option
(Fedora main repo, pure C) but has no file/folder search. vicinae won on features.

Two things about vicinae are deliberate and easy to undo by accident:

1. **`--no-extension-runtime`**, set via the tracked drop-in
   `configs/linux/systemd/vicinae-override.conf`. By default the server spawns a Node process
   (`extension-manager.js`, ~74MB) to host TypeScript/Raycast extensions *even with none
   installed* — that node runtime is this launcher's entire npm supply-chain surface. No
   extensions are used, so it is switched off. Removing the drop-in brings it back.
2. **`layer_shell` is disabled** in `configs/linux/vicinae/settings.json`. As a layer surface,
   vicinae is invisible to xremap (`hyprctl activewindow` keeps reporting the previously focused
   window), so the mac-style Super shortcuts get suppressed inside it. As a regular window it has
   class `vicinae` and they work. Consequences: blur comes from a `windowrule` in hyprland.conf
   rather than a layerrule, and vicinae is excluded from xremap keymap block 3 so its own Ctrl
   chords (Ctrl+B action panel, Ctrl+P, Ctrl+E/N/D/R/S/X) are not eaten.
