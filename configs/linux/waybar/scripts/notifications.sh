#!/usr/bin/env bash
# Waybar custom/notifications — mako state. Replaces swaync-client -swb.
# mako has no subscribe endpoint, so this is polled and signalled on RTMIN+8.
#   text  : bell glyph, plus the history count when there is one
#   class : dnd | unread | none  (styled in style.css)
set -uo pipefail

# Glyphs as explicit escapes, never literals: a literal nerd-font codepoint gets
# silently stripped by some editors and heredocs, and the module then renders as
# an empty slot. U+F0F3 nf-fa-bell, U+F1F6 nf-fa-bell-slash.
BELL=$(printf '')
BELL_OFF=$(printf '')

if ! makoctl mode >/dev/null 2>&1; then
    printf '{"text":"%s","tooltip":"mako not running","class":"none"}\n' "$BELL_OFF"
    exit 0
fi

dnd=0
makoctl mode 2>/dev/null | grep -qx 'do-not-disturb' && dnd=1

# `list`, not `history`: history only ever grows (it drains one at a time via
# `restore` and mako has no clear-history verb), so a history badge sticks at
# max-history forever. `list` is what is still on screen and middle-click zeroes
# it -- which in practice means the badge appears exactly for the notifications
# that do not expire, i.e. critical ones still waiting on you.
count=$(makoctl list -j 2>/dev/null | python3 -c '
import sys, json
try:
    print(len(json.load(sys.stdin)))
except Exception:
    print(0)' 2>/dev/null || echo 0)

if (( dnd )); then
    icon="$BELL_OFF"
    cls="dnd"
    tip="Do not disturb"
elif (( count > 0 )); then
    icon="$BELL $count"
    cls="unread"
    tip="$count waiting"
else
    # The bell persists when idle rather than collapsing to an empty slot -- it is
    # the notification-centre affordance, not just an unread badge. CSS dims it.
    icon="$BELL"
    cls="none"
    tip="No notifications"
fi

printf '{"text":"%s","tooltip":"%s · L restore · R do-not-disturb · M clear","class":"%s"}\n' \
    "$icon" "$tip" "$cls"
