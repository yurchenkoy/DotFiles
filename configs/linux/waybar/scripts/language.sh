#!/usr/bin/env bash
# Waybar custom/language — current main keyboard layout as an UPPERCASE code.
# Click toggles collapsed (icon only) <-> expanded (icon + code); see language-toggle.sh.
set -euo pipefail

ICON=''   # nf-fa-keyboard
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/lang-collapsed"

if [[ -f "$STATE" ]]; then
    printf '%s\n' "$ICON"
    exit 0
fi

km=$(hyprctl devices -j 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
kbs = d.get("keyboards", [])
m = next((k for k in kbs if k.get("main")), kbs[0] if kbs else {})
print(m.get("active_keymap", ""))' 2>/dev/null || true)

case "$km" in
    *"(US)"*|English*) code="US" ;;
    *Norwegian*|*Norsk*) code="NO" ;;
    *) code=$(printf '%s' "${km:0:2}" | tr '[:lower:]' '[:upper:]') ;;
esac

printf '%s %s\n' "$ICON" "$code"
