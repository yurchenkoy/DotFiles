#!/usr/bin/env bash
# Waybar custom/notifications — mako state. Replaces swaync-client -swb.
# mako has no subscribe endpoint, so this is polled and signalled on RTMIN+8.
#   text  : bell glyph, plus the history count when there is one
#   class : dnd | unread | none  (styled in style.css)
set -uo pipefail

if ! makoctl mode >/dev/null 2>&1; then
    printf '{"text":"","tooltip":"mako not running","class":"none"}\n'
    exit 0
fi

dnd=0
makoctl mode 2>/dev/null | grep -qx 'do-not-disturb' && dnd=1

count=$(makoctl history -j 2>/dev/null | python3 -c '
import sys, json
try:
    print(len(json.load(sys.stdin)))
except Exception:
    print(0)' 2>/dev/null || echo 0)

if (( dnd )); then
    icon=''; cls="dnd";    tip="Do not disturb"
elif (( count > 0 )); then
    icon=" $count"; cls="unread"; tip="$count in history"
else
    icon=''; cls="none";   tip="No notifications"
fi

printf '{"text":"%s","tooltip":"%s · L restore · R do-not-disturb · M clear","class":"%s"}\n' \
    "$icon" "$tip" "$cls"
