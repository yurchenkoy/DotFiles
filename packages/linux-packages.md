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

**Hyprland config format: `.conf` → `.lua` (migrated 2026-08-29).** Hyprland 0.56 demoted the
hyprlang `.conf` format to legacy and removes it entirely in 0.57, so `hyprland.conf` became
`hyprland.lua`. Consequences worth knowing:

- The palette reaches Hyprland as a Lua module (`colors.lua`, `require("colors")`) instead of
  `source = colors.conf`. `theme-apply` emits it. hyprlock is a **separate binary** and still
  parses its own `.conf` — `hyprlock.conf` / `hyprlock-colors.conf` are untouched by this.
- Validate any edit with `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`, which parses
  without starting a compositor. Under a Lua config `hyprctl eval '<lua>'` also works.
- Switching format needs a full **logout/login**: the config manager is picked at startup, so
  `hyprctl reload` will NOT move an already-running session from `.conf` to `.lua`.
- `movetoworkspacesilent` has no Lua equivalent — `silent` is not a valid key and unknown keys
  are dropped **without an error** when a valid key is present, so the naive port silently
  follows the window. hyprland.lua restores the previous workspace after the move instead.

**Waybar workspace clicking is broken under the Lua config (upstream bug).** The Lua config
manager evaluates the IPC `dispatch` command as Lua, so the legacy form Waybar 0.15.0 hardcodes
(`dispatch focusworkspaceoncurrentmonitor <id>`, in `src/modules/hyprland/workspace.cpp`) is a
syntax error and the click is a no-op. Not fixable from hyprland.lua: Waybar writes to
`.socket.sock` directly, so a `hyprctl` wrapper cannot intercept it, and `workspace 4` fails at
parse before any Lua name lookup. Waybar has no per-workspace `on-click` to override either.
Scroll-to-switch IS restored, via `on-scroll-up`/`on-scroll-down` in `configs/linux/waybar/
config.jsonc` — Waybar delegates to those when set, bypassing its broken path.

**Fixed upstream on `master`; the gate is now a release, not the code (checked 2026-09-04).**
`IPC::dispatch` queries `systeminfo`, and on `configProvider: lua` routes through
`buildLuaDispatch()` to emit `hl.dsp.focus({ workspace = "1" })` — commits `74cf45d5`
(2026-07-05), `bfd0cfee` (2026-07-30, fixes #5198), `92742e46` (2026-08-05), `0f12de93`
(2026-08-09). **Check `src/modules/hyprland/backend.cpp`, NOT `workspace.cpp`** — the call sites
still read `IPC::dispatch("focusworkspaceoncurrentmonitor", ...)` because the translation happens
a layer below them, so grepping `workspace.cpp` makes a fixed tree look broken. That mistake is
why this file previously claimed master was still legacy as of 2026-08-29; it had been fixed
since 2026-07-30.

The blocker is that the latest release, 0.15.0, is from 2026-02-06 — older than every fix commit,
and what Fedora ships (`waybar-0.15.0-2.fc44`; `dnf list --showduplicates waybar` offers nothing
newer). So watch releases, not the source: the fix arrives with 0.16.0. On upgrading, drop the
two `on-scroll-*` overrides so the built-in monitor-relative scrolling returns, and verify by
clicking a workspace number.

Anything else scripted against `hyprctl dispatch` has the same problem. The new form is
`hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`. Note `hl.dsp.exec_raw("workspace 3")` is
NOT a legacy escape hatch despite being suggested upstream — it tries to exec a binary.

**`hyprland-guiutils` is not packaged in the ashbuk COPR.** Hyprland warns about it at startup.
It is a soft runtime dep supplying optional Qt dialogs (config-error popup, update/donate
screens); the compositor is fully functional without it, and nothing else in the COPR or Fedora
repos provides it. The warning is silenced with `misc.disable_hyprland_guiutils_check = true`
in hyprland.lua. If you ever want the dialogs, it has to be built from source.

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
   class `vicinae` and they work. Consequences: blur comes from a `hl.window_rule` in hyprland.lua
   rather than a layerrule, and vicinae is excluded from xremap keymap block 3 so its own Ctrl
   chords (Ctrl+B action panel, Ctrl+P, Ctrl+E/N/D/R/S/X) are not eaten.
