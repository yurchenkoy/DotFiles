#!/usr/bin/env bash
# Waybar custom/steam — show icon only when Steam is running (Super+Q just hides it).
if pgrep -x steam >/dev/null 2>&1; then
    echo '{"text":"","tooltip":"Steam running — click to quit","class":"running"}'
else
    echo '{"text":"","tooltip":""}'
fi
