# Linux packages (source of truth — install by hand)

No runnable installer: names and availability vary by distro. This is the logical list, with the
Fedora 44 and Arch commands side by side. Arch is the column to trust going forward.

Arch needs `multilib` uncommented in `/etc/pacman.conf` before Steam, and an AUR helper
(`paru`/`yay`) for the few AUR rows.

| Tool | Fedora 44 | Arch | Notes |
|---|---|---|---|
| neovim | `dnf install neovim` | `pacman -S neovim` | |
| eza | `dnf install eza` | `pacman -S eza` | |
| fd | `dnf install fd-find` | `pacman -S fd` | binary is `fd` on both |
| fzf | `dnf install fzf` | `pacman -S fzf` | |
| ripgrep | `dnf install ripgrep` | `pacman -S ripgrep` | |
| zoxide | `dnf install zoxide` | `pacman -S zoxide` | |
| gh | `dnf install gh` | `pacman -S github-cli` | |
| tree | `dnf install tree` | `pacman -S tree` | |
| git | `dnf install git` | `pacman -S git` | |
| node | `dnf install nodejs24 nodejs24-npm nodejs24-bin` | `pacman -S nodejs npm` | Fedora versions the package |
| dotnet | `dnf install dotnet-sdk-10.0` | `pacman -S dotnet-sdk` | v10, not 8 |
| starship | COPR `atim/starship` | `pacman -S starship` | no third-party repo needed on Arch |
| zsh-autosuggestions | `dnf install zsh-autosuggestions` | `pacman -S zsh-autosuggestions` | **path differs** — see Desktop notes |
| zsh-completions | git clone → `~/.local/share/zsh/plugins/` | `pacman -S zsh-completions` | clone works on both |
| fzf-tab | git clone → `~/.local/share/zsh/plugins/` | AUR `zsh-fzf-tab-git` | |
| fast-syntax-highlighting | git clone → `~/.local/share/zsh/plugins/` | AUR | |
| Nerd Fonts | manual → `~/.local/share/fonts/` | `pacman -S ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd` | `fc-cache -f` after a manual drop |
| Symbols Nerd Font | manual, `NerdFontsSymbolsOnly.zip` | `pacman -S ttf-nerd-fonts-symbols` | full-size Waybar icons; Mono variants squish glyphs |
| ghostty | `dnf install ghostty` | `pacman -S ghostty` | |
| wl-clipboard | `dnf install wl-clipboard` | `pacman -S wl-clipboard` | nvim system clipboard |
| Proton Pass | RPM from proton.me | AUR `proton-pass-bin` | SSH agent for git signing (paid plan) |
| xremap | prebuilt binary → `/usr/local/bin` | AUR (→ `/usr/bin`) | path resolved at runtime in hyprland.lua |
| hyprland | COPR `ashbuk` | `pacman -S hyprland` | Arch has it in `extra`, same 0.56.2 |
| hyprland-guiutils | **unavailable** | `pacman -S hyprland-guiutils` | install on Arch and drop `disable_hyprland_guiutils_check` |
| polkit agent | *(none installed — see below)* | `pacman -S hyprpolkitagent` | **currently missing on this box** |
| waybar | `dnf install waybar` | `pacman -S waybar` | both ship 0.15.0; see the workspace-click note |
| wallpaper | `dnf install swaybg` | `pacman -S hyprpaper` | swaybg only because hyprpaper broke on Fedora's COPRs |
| fuzzel | `dnf install fuzzel` | `pacman -S fuzzel` | launcher + dmenu front-end |
| mako | `dnf install mako` | `pacman -S mako` | notifications |
| hyprlock / hypridle | `dnf install hyprlock` | `pacman -S hyprlock hypridle` | configs rebuilt from scratch on Arch |
| wlogout | `dnf install wlogout` | AUR `wlogout` | power menu grid |
| grim + slurp + swappy | `dnf install grim slurp swappy` | `pacman -S grim slurp swappy` | screenshots + annotate |
| pavucontrol | `dnf install pavucontrol` | `pacman -S pavucontrol` | Waybar audio click |
| upower | preinstalled | `pacman -S upower` | Bluetooth battery in Waybar |
| greetd + tuigreet | `dnf install greetd tuigreet` | `pacman -S greetd` + AUR `greetd-tuigreet` | login |

Skipped vs mac: python@3.11 (system python is newer), spotify.

## Desktop notes

Non-obvious things that cost time to work out. Each one is a decision you can accidentally undo.

**Hyprland's config is Lua.** 0.56 demoted hyprlang `.conf` to legacy; 0.57 drops it.

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

**Waybar workspace click and scroll are both dead under the Lua config.** Waybar 0.15.0 sends the
legacy dispatch string, which the Lua config manager rejects. `Caps+1..9` is the working path.

Fixed upstream in `IPC::dispatch`, but **0.16.0 is unreleased** and Arch's `extra/waybar` ships
the same 0.15.0. The fix on Arch is `waybar-git` or a manual build of `master`, not the package.

⚠ Verify by *release*, never by grepping the source: the call sites in `workspace.cpp` still read
as legacy even in a fixed tree, because the translation happens below them in `backend.cpp`. That
mistake has already been made once.


**`hyprland-guiutils` is missing from the ashbuk COPR** — optional Qt dialogs (config-error popup,
update screens), nothing else provides it, so the nag is silenced with
`misc.disable_hyprland_guiutils_check` in hyprland.lua. Arch has it in `extra`: **install it there
and delete that line**, or you keep suppressing Hyprland's own error dialogs for no reason.

**There is no polkit authentication agent on this box.** The autostart pointed at
`/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1`, a path that does not exist here — so
it has been failing silently and GUI privilege prompts never appear. hyprland.lua now walks a
candidate list instead of one hardcoded path, but a candidate still has to be installed:
`hyprpolkitagent` on Arch.

**Distro-dependent paths, resolved at runtime rather than hardcoded:** `zsh-autosuggestions` sits
in `/usr/share/zsh-autosuggestions/` on Fedora and `/usr/share/zsh/plugins/zsh-autosuggestions/` on
Arch (`linux/zsh/os.zsh` tries both, and `common.zsh` guards the `source` — unguarded it errors on
every shell start); `xremap` is a hand-placed `/usr/local/bin` binary on Fedora and a packaged
`/usr/bin` one on Arch.

**fuzzel** is the launcher (`Super+Space`) and the dmenu front-end for wrapper scripts.

- `fuzzel --dmenu </dev/null` is a config check — an unknown key exits non-zero and names it.
- Colours are `rrggbbaa` with **no** `#`; fonts use fontconfig `family:size=N`. mako below wants
  the opposite of both.
- `width` is in characters, `lines` in lines, not pixels.
- `namespace` is set explicitly so the blur `hl.layer_rule` matches. Keep the two in sync.
- **It is layer-shell only**, so `hyprctl activewindow` never reports it and **xremap cannot see
  it**. Its `[key-bindings]` section is therefore the only place to fix keys inside the launcher.
  XKB names there: `Mod4`=Super, `Mod1`=Alt; `Super` and `Mod3` are rejected.

**mako** handles notifications: one INI plus a generated colour fragment.

- Per-source styling is the point: `notify-send -a <name>` matches an `[app-name=<name>]` block.
  Criteria match top to bottom and the **last** match wins per option.
- No notification-centre UI. `makoctl history`/`restore` is a buffer that only drains one at a
  time, so the waybar badge counts `makoctl list` instead.
- `makoctl list`/`history` need `-j` for JSON, and return a plain array.
