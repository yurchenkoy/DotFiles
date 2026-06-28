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
| keepassxc | `dnf install keepassxc` | SSH agent for git signing |
| xremap | prebuilt binary → `/usr/local/bin/xremap` | not packaged |
| hyprland + waybar + wofi + hyprlock | `dnf install` | compositor stack (mako dropped, see below) |
| swaybg | `dnf install swaybg` | wallpaper (replaces hyprpaper, which is broken on Fedora's mixed Hyprland COPRs — see note) |
| rofi | `dnf install rofi` | Super+Space launcher (prefix matching: apps by default, folders when query starts with a space) |
| SwayNotificationCenter | `dnf install SwayNotificationCenter` | notifications + history panel (replaces mako) |
| wlogout | `dnf install wlogout` | power menu grid |
| grim + slurp + swappy | `dnf install grim slurp swappy` | screenshots + annotate |
| pavucontrol | `dnf install pavucontrol` | audio control (Waybar audio click) |
| upower | preinstalled | per-device Bluetooth battery in Waybar |
| greetd + tuigreet | `dnf install greetd tuigreet` | login |

Skipped vs mac: python@3.11 (system python newer), spotify, caffeine / hypridle (no idle management — declined).
