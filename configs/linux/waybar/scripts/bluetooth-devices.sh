#!/usr/bin/env bash
# Waybar custom/bluetooth — up to 3 connected devices as ABBREV + battery%.
# Abbreviation: leading alphanumeric run up to first space/symbol, capped 3 chars,
# overridable via bluetooth-rename.conf (MAC=Label, one per line).
set -euo pipefail

json_str() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

RENAME="${HOME}/.config/waybar/bluetooth-rename.conf"

declare -A LABEL
if [[ -r "$RENAME" ]]; then
    while IFS='=' read -r mac lbl; do
        [[ -z "$mac" || "$mac" == \#* ]] && continue
        LABEL["${mac^^}"]="$lbl"
    done < "$RENAME"
fi

abbrev() {  # $1 = device name -> <=3 char abbreviation
    local run="${1%%[^A-Za-z0-9]*}"
    if [[ -z "$run" ]]; then
        local stripped="${1##[^A-Za-z0-9]}"   # drop one leading symbol
        run="${stripped%%[^A-Za-z0-9]*}"
        [[ -z "$run" ]] && run="BT"
    fi
    printf '%.3s' "$run"
}

mapfile -t macs < <(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
parts=(); tip=""
for mac in "${macs[@]:0:3}"; do
    name=$(bluetoothctl info "$mac" | awk -F': ' '/Name:/{print $2; exit}')
    [[ -z "$name" ]] && name="$mac"
    short="${LABEL[${mac^^}]:-$(abbrev "$name")}"
    # battery via upower (HID devices that report it)
    updev=$(upower -e | grep -i "${mac//:/_}" | head -1 || true)
    batt=""
    if [[ -n "$updev" ]]; then
        pct=$(upower -i "$updev" | awk '/percentage:/{gsub("%","",$2); print $2; exit}')
        [[ -n "$pct" ]] && batt=" ${pct}%"
    fi
    parts+=("$(json_str "$short")${batt}")
    tip+="$(json_str "$name")${batt:+ — ${batt# }}\n"
done

if (( ${#parts[@]} == 0 )); then
    echo '{"text":"","tooltip":"No Bluetooth devices","class":"off"}'
else
    text=$(IFS=' '; echo " ${parts[*]}")
    printf '{"text":"%s","tooltip":"%s","class":"on"}\n' "$text" "${tip%\\n}"
fi
