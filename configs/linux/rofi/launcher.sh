#!/usr/bin/env bash
# Combined rofi launcher (prefix matching):
#   • type letters     → desktop apps whose name STARTS with those letters → gtk-launch
#   • start with SPACE → folders under $HOME whose name starts with the rest → xdg-open
#
# How the leading-space gate works: app rows are plain "Name"; folder rows are
# " Name\tPATH" (leading space). With rofi `-matching prefix`, "Gho" only matches the
# app rows (folders start with a space) and " Down" only matches folder rows.
set -euo pipefail

ROOT="$HOME"
DEPTH=5
APPDIRS=(
    /usr/share/applications
    "$HOME/.local/share/applications"
    /var/lib/flatpak/exports/share/applications
    "$HOME/.local/share/flatpak/exports/share/applications"
)
TAB=$'\t'

emit_apps() {
    for d in "${APPDIRS[@]}"; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.desktop; do
            [[ -e "$f" ]] || continue
            grep -qiE '^(NoDisplay|Hidden)[[:space:]]*=[[:space:]]*true' "$f" && continue
            awk -F= '/^Name=/{print $2; exit}' "$f"
        done
    done | LC_ALL=C sort -u
}

emit_folders() {
    # visible (non-hidden) dirs; display " <basename>\t<full path>" (leading space = folder mode)
    fd -t d -d "$DEPTH" -E node_modules -E .git -E .cache . "$ROOT" 2>/dev/null \
        | while IFS= read -r p; do
            p="${p%/}"                                   # fd appends a trailing slash to dirs
            printf ' %s%s%s\n' "${p##*/}" "$TAB" "$p"
        done
}

sel=$( { emit_apps; emit_folders; } \
    | rofi -dmenu -i -matching prefix -p "Search" -no-custom \
           -theme "$HOME/.config/rofi/config.rasi" 2>/dev/null ) || exit 0
[[ -z "$sel" ]] && exit 0

if [[ "$sel" == " "* ]]; then
    # folder row: " basename\t/full/path" — open the path after the tab
    path="${sel#*$TAB}"
    [[ -d "$path" ]] && exec xdg-open "$path"
else
    # app row: resolve Name → .desktop id → gtk-launch
    for d in "${APPDIRS[@]}"; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.desktop; do
            [[ -e "$f" ]] || continue
            [[ "$(awk -F= '/^Name=/{print $2; exit}' "$f")" == "$sel" ]] || continue
            base="${f##*/}"
            exec gtk-launch "${base%.desktop}"
        done
    done
fi
