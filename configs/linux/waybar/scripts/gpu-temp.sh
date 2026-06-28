#!/usr/bin/env bash
# Waybar custom/gpu — Nvidia GPU temperature.
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
[[ -z "$temp" ]] && { echo '{"text":"󰢮 --","tooltip":"nvidia-smi unavailable"}'; exit 0; }
cls="ok"; (( temp >= 75 )) && cls="warn"; (( temp >= 85 )) && cls="crit"
printf '{"text":"󰢮 %s°C","tooltip":"GPU %s°C","class":"%s"}\n' "$temp" "$temp" "$cls"
