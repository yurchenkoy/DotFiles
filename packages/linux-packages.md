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
| hyprland + waybar + hyprlock | `dnf install` | compositor stack |
| swaybg | `dnf install swaybg` | wallpaper; replaces hyprpaper, which is broken on Fedora's mixed Hyprland COPRs |
| vicinae | `dnf copr enable scottames/vicinae` → `dnf install vicinae` | Super+Space launcher. Daemon; started by `exec-once = systemctl --user start vicinae` because `graphical-session.target` never activates without uwsm. See Desktop notes. |
| SwayNotificationCenter | `dnf install SwayNotificationCenter` | notifications + history panel (replaces mako) |
| wlogout | `dnf install wlogout` | power menu grid |
| grim + slurp + swappy | `dnf install grim slurp swappy` | screenshots + annotate |
| pavucontrol | `dnf install pavucontrol` | audio control (Waybar audio click) |
| upower | preinstalled | per-device Bluetooth battery in Waybar |
| greetd + tuigreet | `dnf install greetd tuigreet` | login |

Skipped vs mac: python@3.11 (system python newer), spotify, caffeine / hypridle (no idle management — declined).

## Desktop notes

Non-obvious things that cost time to work out. Each one is a decision you can accidentally undo.

**Hyprland's config is Lua** (`hyprland.lua`, migrated 2026-08-29) — 0.56 demoted hyprlang
`.conf` to legacy and 0.57 drops it.

- The palette is a Lua module (`require("colors")`), emitted by `theme-apply`. hyprlock is a
  separate binary and still parses its own `.conf`.
- Check edits with `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` — no compositor needed.
- The format is picked at startup: switching needs a full logout/login, not `hyprctl reload`.
- `movetoworkspacesilent` has no Lua equivalent. `silent` is not a valid key, and unknown keys are
  dropped *without error* when a valid one is present, so the naive port silently follows the
  window; `hyprland.lua` re-focuses the previous workspace instead.
- Scripted dispatches need the new form: `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`.
  `hl.dsp.exec_raw` is not a legacy escape hatch despite upstream suggestions — it execs a binary.

**Waybar workspace clicks are dead under the Lua config.** Waybar 0.15.0 sends the legacy dispatch
string, which the Lua config manager rejects; no config can fix it. Scrolling *is* restored via
`on-scroll-up`/`on-scroll-down` in `waybar/config.jsonc`. Fixed upstream in `IPC::dispatch`
(`backend.cpp` — **not** `workspace.cpp`, whose call sites still look legacy) but unreleased:
0.15.0 (2026-02) predates the fix. Drop the two overrides when 0.16.0 lands.

**`hyprland-guiutils` is missing from the ashbuk COPR** — optional Qt dialogs only, nothing else
provides it. Warning silenced with `misc.disable_hyprland_guiutils_check` in hyprland.lua.

**vicinae replaced rofi, wofi and fuzzel** (rofi rescanned `$HOME` per keypress; fuzzel has no file
search). Two settings are deliberate:

1. **`--no-extension-runtime`**, via `configs/linux/systemd/vicinae-override.conf`. The server
   otherwise spawns a ~74MB Node process to host Raycast extensions *even with none installed* —
   the launcher's entire npm supply-chain surface. Removing the drop-in brings it back.
2. **`layer_shell` disabled**, in `configs/linux/vicinae/settings.json`. As a layer surface vicinae
   is invisible to xremap (`hyprctl activewindow` reports the previous window), so the Super
   shortcuts get suppressed inside it; as a normal window (class `vicinae`) they work. Hence blur
   comes from a `hl.window_rule`, and vicinae is excluded from xremap keymap block 3 so its own
   Ctrl chords are not eaten.
