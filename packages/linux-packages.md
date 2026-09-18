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
- **`MOD3` must be uppercase.** The Lua key parser rejects `Mod3`, silently binding nothing.
- **`group_aware = true` on `hl.dsp.window.move` merges** a window into a group rather than
  swapping the two. This is the legacy `movewindoworgroup`; established by A/B test.
- `hyprctl binds -j` reports every Lua bind as `dispatcher="__lua"` with an opaque id, so bind
  *actions* cannot be diffed textually. Trigger fields (modmask/key/flags) still can.

**Waybar workspace clicks are dead under the Lua config.** Waybar 0.15.0 sends the legacy dispatch
string, which the Lua config manager rejects; no config can fix it. Scrolling *is* restored via
`on-scroll-up`/`on-scroll-down` in `waybar/config.jsonc`. Fixed upstream in `IPC::dispatch`
(`backend.cpp` — **not** `workspace.cpp`, whose call sites still look legacy) but unreleased:
0.15.0 (2026-02) predates the fix. Drop the two overrides when 0.16.0 lands.

**`hyprland-guiutils` is missing from the ashbuk COPR** — optional Qt dialogs only, nothing else
provides it. Warning silenced with `misc.disable_hyprland_guiutils_check` in hyprland.lua.

**fuzzel replaced vicinae** as the launcher (`Super+Space`), and is also the dmenu front-end for
the `fz-*` wrapper scripts. Things worth knowing before editing `fuzzel.ini`:

- **It validates itself.** An unknown key makes fuzzel exit non-zero and name the key, so
  `fuzzel --dmenu </dev/null` is a config check. Use it after every edit.
- Colours are `rrggbbaa` **without** a leading `#`, and fonts use fontconfig syntax
  (`family:size=N`). mako, right below, wants `#rrggbbaa` and Pango `Family Size`. Easy to swap.
- `width` is in **characters** and `lines` in **lines**, not pixels.
- It has an `include` directive, so its palette is generated by `theme-apply` like waybar's.
- `namespace` is set explicitly so the blur `hl.layer_rule` matches a name we chose. Keep the two
  in sync. fuzzel is **layer-shell only** — there is no "render as a normal window" mode, which
  has one consequence worth remembering: `hyprctl activewindow` never reports it, so **xremap
  cannot see it at all**. Whichever xremap block applies inside the launcher is decided by the
  *previously* focused window. (vicinae dodged this by disabling layer-shell; fuzzel cannot.)

**mako replaced SwayNotificationCenter.** One INI plus a generated colour fragment.

- Per-source styling is the point: scripts announce themselves with `notify-send -a <name>` and
  get a `[app-name=<name>]` block. Criteria match top to bottom and the **last** match wins per
  option, so keep the generic `[urgency=…]` blocks above the per-app ones.
- Criteria inside the `include`d fragment are parsed normally — verified, not assumed.
- Given up vs swaync: the notification-centre panel (mako has a history buffer via
  `makoctl history`/`restore`, but no UI) and CSS theming. Gained: per-app rules and modes.
- **swaync is dbus-activatable**, so it respawns while anything still calls `swaync-client`.
  Change the waybar module first, then swap daemons.
- `makoctl list`/`history` need `-j` for JSON, and return a plain array.
