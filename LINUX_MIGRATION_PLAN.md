# Linux Migration Plan — macOS muscle memory → Fedora 44 / Hyprland

Goal: replicate the macOS (AeroSpace + Karabiner) keyboard scheme and dev environment on a
fresh Fedora 44 + Hyprland install, then extend this dotfiles repo to manage Linux alongside macOS.

---

## Machine reality check (what's actually on this box)

| Brief assumed | Reality | Consequence |
|---|---|---|
| Omarchy handles Super/Ctrl rebinding | **No Omarchy** — vanilla Hyprland `0.55.4` with a hand-rolled `~/.config/hypr/hyprland.conf` | We own *all* the rebinding ourselves; nothing is done for us |
| zsh is default shell | ✅ Confirmed — `/usr/bin/zsh` is the login shell. `~/.zshrc` is an unconfigured 3-line stub | No `chsh` needed; just configure `.zshrc` |
| Steam never set up | Steam **RPM already installed**; no Proton-GE; `flatpak` not installed | Skip Steam install; add Proton-GE only |
| Caps via xremap (tap=Esc, hold=Hyper) | Currently XKB `caps:hyper` → hold=Hyper works, **no tap=Escape** | Move the tap behavior to xremap |
| — | **xremap 0.15.8 already installed**, systemd user service enabled, user already in `input` group | Big head start — just needs a config file |
| Port GPG signing | **No GPG secret keys** here; gitconfig references key `5AAD2621…` (on the Mac) | New signing key needed (decision below) |

---

## The core keybinding architecture

The insight from the macOS setup: **Super+C/V for copy/paste** keeps **Ctrl+C free in the terminal**
for SIGINT. Replicated on Linux with a deliberate two-layer split:

### Layer 1 — Hyprland (`~/.config/hypr/hyprland.conf`) — window management
Caps Lock acts as **Hyper**. Mirrors AeroSpace muscle memory:
- `Caps + h/j/k/l` → focus  (already working)
- `Caps + Super + h/j/k/l` → move window  (already working)
- `Caps + 1..9` → workspace  (currently only 1–5 → extend to 9)
- `Caps + Super + 1..9` → send window to workspace
- Layout toggles, fullscreen, float toggle, monitor moves, workspace-back-and-forth
- `Super + W` → close app · `Super + Return` → terminal · `Super + Space` → launcher
- **Excluded per request:** resize mode, service mode (not ported)

### Layer 2 — xremap (`~/.config/xremap/config.yml`) — app-level key translation
- **`modmap` CapsLock dual-role** (replicates Karabiner): `alone: Esc`, `held: Hyper`.
- **`keymap` Super→Ctrl for GUI apps**: `Super-C→Ctrl-C`, `Super-V→Ctrl-V`, plus
  X/A/Z/Y/F/T/W/L/N, scoped with `application.not: [Ghostty, …]`.
- **Terminal stays native**: Ghostty is *excluded* from the remap. Ghostty's own config binds
  `Super+C/V` to copy/paste, so **`Ctrl+C` remains SIGINT**. This is the whole trick.
- **Super+1/2/3 → browser tabs**: inside the browser, Super+Number → Ctrl+Number via the same GUI keymap.

### ⚠️ The one real unknown
xremap emits events *below* the XKB layer, so `held: Hyper_L` may or may not register as
Hyprland's `Mod3`/Hyper. **Plan:** test empirically first.
- If it works → xremap drives both tap and hold cleanly.
- If not → fallback: keep XKB `caps:hyper` for the **hold**, use xremap only for the **tap=Escape**.
Either way the binds keep working; only the mechanism behind "hold" differs.

---

## Phases (priority order)

### Priority 1 — Keybindings
1. **xremap `config.yml`** — CapsLock dual-role + Super→Ctrl keymap (Ghostty excluded). Reload
   `xremap.service`; test tap/hold + Super+C/V live.
2. **Extend `hyprland.conf`** — workspaces 1–9, send-to-workspace, layout/float/fullscreen,
   monitor moves, `Super+W` close. (No resize/service mode.)
3. **Ghostty + browser** — Ghostty native Super+C/V copy-paste (Ctrl+C = SIGINT); verify
   Super+1/2/3 tab switching in the browser.

### Priority 2 — Shell, terminal, tools
4. **zsh config** — port `.zshrc` off all `/opt/homebrew/...` paths to Fedora paths (plugin
   source dirs, nvim path, brew-prefix completion logic). Keep LS_COLORS, fzf-tab widgets,
   `prj()` picker, autosuggestions + fast-syntax-highlighting. (No `chsh` — already zsh.)
5. **Install CLI stack** — see package mapping below.
6. **Port starship + nvim/LazyVim** — largely platform-agnostic; check for mac-only paths.
7. **Git config + new signing key** — port `.gitconfig` (fix `gpg.program`, editor=nvim);
   create a **new** signing key (decision below); add to GitHub; update `signingkey`.

### Priority 3 — Steam + Proton-GE
8. Keep the installed **native RPM Steam**. Install **GE-Proton via the ProtonUp-Qt AppImage**
   (single binary, *no new package manager*) into `~/.steam/root/compatibilitytools.d/`.
   Fallback: manual GE-Proton tarball from GitHub releases. **No flatpak.**

### Priority 4 — Repo
9. Restructure repo so Linux configs (hypr, xremap) live alongside macOS ones; teach
   `dotfiles-collect`/`distribute` about OS-specific source/destination paths and the
   bash-vs-zsh shebang; add the Packages→dnf mapping; update README for Linux setup.

### Priority 5 — Ricing (lowest)
10. Waybar, Hyprland animations, rounded corners, transparency/blur — Tokyo Night aesthetic.

---

## Decisions resolved

### Git signing — **new key**
You leaned toward a new key and mentioned **KeePassXC**.
- KeePassXC can't natively *hold* a GPG private key (gpg-agent owns that; KeePassXC would only
  store the passphrase).
- KeePassXC **is** a first-class **SSH agent** — it can store an SSH signing key and sign commits
  via git's `gpg.format=ssh`.
- **Recommendation:** make the new key an **SSH signing key in KeePassXC** (same "new key"
  outcome, but KeePassXC actually adds value). New-GPG-key remains available if preferred.
  Final GPG-vs-SSH call happens at this step.

### Steam — **avoid flatpak entirely**
Native RPM Steam (already installed) + **ProtonUp-Qt AppImage**. No new package manager,
no Steam reinstall.

---

## `Packages` → Fedora mapping

| macOS pkg | Fedora source | Notes |
|---|---|---|
| neovim | `dnf install neovim` | |
| eza | `dnf install eza` | in Fedora repos |
| fd | `dnf install fd-find` | binary is `fd` |
| fzf | `dnf install fzf` | |
| ripgrep | already installed (`rg`) | |
| zoxide | `dnf install zoxide` | |
| gh | `dnf install gh` | |
| tree | `dnf install tree` | |
| node | `dnf install nodejs` | 
| dotnet | `dnf install dotnet-sdk-8.0` (or MS repo) | 
| python@3.11 | `dnf install python3.11` | |
| starship | COPR `atim/starship` or official installer | not in base repos |
| zsh-autosuggestions | `dnf install zsh-autosuggestions` | |
| zsh-completions | git clone | not packaged |
| zsh-fast-syntax-highlighting | git clone (zdharma-continuum) | not packaged |
| fzf-tab | git clone (Aloxaf/fzf-tab) | not packaged |
| JetBrains Mono Nerd Font | download / COPR | |
| Aydia Cove Nerd Font | manual download | |
| ghostty | already installed | |
| spotify | flatpak / RPM repo — confirm if wanted | |
| caffeine | replace with `hypridle` inhibit | |

"uncertain if I need it" items (node, protobuf, graphviz, wimlib, dotnet, zoxide) — I'll confirm
each with you before installing rather than pulling them all in.

---

## Notes / risks
- Editing keybindings live can momentarily change how the current session responds to keys
  (nothing destructive).
- The xremap `held: Hyper` question (above) is the only genuine technical unknown; everything else
  is well-trodden.
- Nvidia env vars are already set in `hyprland.conf` — leaving them untouched.
