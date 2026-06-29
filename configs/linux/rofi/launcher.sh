#!/usr/bin/env bash
# Combined rofi launcher (TokyoNight, prefix matching):
#   • type letters    → desktop apps whose name STARTS with the query → gtk-launch
#   • prefix with "_" → folders under $HOME whose name starts with the rest → xdg-open
#
# Why "_" and not "/" or "~": this rofi's matcher strips/splits on / ~ . : ' (so a bare
# "Down" would wrongly match a "/Downloads" row). "_" is the one separator rofi keeps
# INSIDE the token, so it cleanly gates folder rows. Apps stay plain names; folders are
# shown as "_<name>". The folder PATH is never put in the row text (it would leak the
# gate via its own path components) — it's resolved from the FOLDER map on selection.
#
# Icons: the dmenu icon metadata (\0icon\x1f<name>) MUST be emitted directly in the
# printf format string — bash silently drops NUL bytes stored in variables.
set -euo pipefail

ROOT="$HOME"
DEPTH=5
THEME="$HOME/.config/rofi/config.rasi"
APPDIRS=(
    /usr/share/applications
    "$HOME/.local/share/applications"
    /var/lib/flatpak/exports/share/applications
    "$HOME/.local/share/flatpak/exports/share/applications"
)

# name -> .desktop id, name -> icon  (first definition wins)
declare -A APP_ID APP_ICON
for d in "${APPDIRS[@]}"; do
    [[ -d "$d" ]] || continue
    for f in "$d"/*.desktop; do
        [[ -e "$f" ]] || continue
        grep -qiE '^(NoDisplay|Hidden)[[:space:]]*=[[:space:]]*true' "$f" && continue
        name=$(awk -F= '$1=="Name"{sub(/^[^=]*=/,""); print; exit}' "$f")
        [[ -n "$name" ]] || continue
        [[ -n "${APP_ID[$name]+x}" ]] && continue
        icon=$(awk -F= '$1=="Icon"{sub(/^[^=]*=/,""); print; exit}' "$f")
        base="${f##*/}"
        APP_ID[$name]="${base%.desktop}"
        APP_ICON[$name]="${icon:-application-x-executable}"
    done
done

# basename -> full path  (first match wins)
declare -A FOLDER
while IFS= read -r p; do
    p="${p%/}"; b="${p##*/}"
    [[ -n "$b" && -z "${FOLDER[$b]+x}" ]] && FOLDER[$b]="$p"
done < <(fd -t d -d "$DEPTH" -E node_modules -E .git -E .cache . "$ROOT" 2>/dev/null)

emit() {
    local n b
    local -a anames bnames
    mapfile -t anames < <(printf '%s\n' "${!APP_ID[@]}" | LC_ALL=C sort -f)
    for n in "${anames[@]}"; do
        printf '%s\0icon\x1f%s\n' "$n" "${APP_ICON[$n]}"
    done
    mapfile -t bnames < <(printf '%s\n' "${!FOLDER[@]}" | LC_ALL=C sort -f)
    for b in "${bnames[@]}"; do
        printf '_%s\0icon\x1ffolder\n' "$b"
    done
}

sel=$( emit | rofi -dmenu -i -no-custom -no-config -matching prefix -show-icons \
                   -p "Search" -theme "$THEME" 2>/dev/null ) || exit 0
[[ -z "$sel" ]] && exit 0

if [[ "$sel" == _* ]]; then
    path="${FOLDER[${sel#_}]:-}"
    [[ -n "$path" && -d "$path" ]] && exec xdg-open "$path"
    exit 0
fi
id="${APP_ID[$sel]:-}"
[[ -n "$id" ]] && exec gtk-launch "$id"
exit 0
