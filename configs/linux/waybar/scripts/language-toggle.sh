#!/usr/bin/env bash
# Toggle the Waybar language widget between collapsed (icon only) and expanded
# (icon + UPPERCASE code). Flips a state file, then signals Waybar to refresh now.
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/lang-collapsed"
mkdir -p "$(dirname "$STATE")"
if [[ -f "$STATE" ]]; then rm -f "$STATE"; else : > "$STATE"; fi
pkill -RTMIN+7 waybar 2>/dev/null || true
