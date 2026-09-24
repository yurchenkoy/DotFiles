#!/usr/bin/env bash
# Waybar custom/bluetooth — up to 3 connected devices as alias + battery%.
# The alias is the device name unless renamed: bluetoothctl -> select/set-alias <label>.
set -euo pipefail

json_str() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

# bt_battery <MAC> -> prints battery percentage digits, or nothing.
# Matches a upower device either by MAC in its object path (bluez HID batteries)
# OR by its `serial:` field equalling the MAC (Logitech HID++ devices like the MX
# Master expose battery as hidpp_battery_N, whose path has no MAC but serial == MAC).
bt_battery() {
    local mac="${1,,}" mac_us; mac_us="${mac//:/_}"
    local dev info serial pct
    while IFS= read -r dev; do
        [[ -z "$dev" ]] && continue
        info=$(upower -i "$dev" 2>/dev/null) || continue
        serial=$(awk -F': ' '/serial:/{gsub(/ /,"",$2); print tolower($2); exit}' <<<"$info")
        if [[ "${dev,,}" == *"$mac_us"* || "$serial" == "$mac" ]]; then
            pct=$(awk '/percentage:/{gsub("%","",$2); print $2; exit}' <<<"$info")
            [[ -n "$pct" ]] && { printf '%s' "$pct"; return 0; }
        fi
    done < <(upower -e 2>/dev/null)
    return 1
}

mapfile -t macs < <(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
parts=(); tip=""
for mac in "${macs[@]:0:3}"; do
    name=$(bluetoothctl info "$mac" | awk -F': ' '/Alias:/ && !n++ {print $2}')
    [[ -z "$name" ]] && name="$mac"
    # battery via upower (bluez HID battery OR Logitech HID++ matched by serial==MAC)
    batt=""
    pct=$(bt_battery "$mac" || true)
    [[ -n "$pct" ]] && batt=" ${pct}%"
    parts+=("$(json_str "$name")${batt}")
    tip+="$(json_str "$name")${batt:+ — ${batt# }}\n"
done

if (( ${#parts[@]} == 0 )); then
    echo '{"text":"","tooltip":"No Bluetooth devices","class":"off"}'
else
    text=$(IFS=' '; echo " ${parts[*]}")
    printf '{"text":"%s","tooltip":"%s","class":"on"}\n' "$text" "${tip%\\n}"
fi
