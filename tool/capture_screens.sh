#!/usr/bin/env bash
# Capture store screenshots off the Android emulator / a real phone, or an
# iOS simulator.
#
#   tool/capture_screens.sh play demo-on     # clean Android status bar
#   tool/capture_screens.sh play 01-home     # capture what is on screen now
#   tool/capture_screens.sh play demo-off
#
#   tool/capture_screens.sh iphone 01-home   # booted iOS simulator
#   tool/capture_screens.sh ipad 01-home
#
# With several simulators booted, "booted" is ambiguous and simctl refuses.
# Pass a UDID as a third argument, or set ATOM_SIM_UDID.
#
# Captures land in store/<target>/raw/<slug>.png at the device's own
# resolution. tool/make_store_screenshots.py composes them into panels.
#
# demo-on puts Android's SystemUI into demo mode: fixed 09:41 clock, full
# battery, full signal, no notification icons. That beats cropping the status
# bar off, because the shot stays an honest picture of the running app and
# still looks deliberate rather than accidental. iOS simulators already show
# a fixed 9:41 clock and a full battery, so they need no equivalent.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

target="${1:-}"
action="${2:-}"

case "$target" in
    play|iphone|ipad) ;;
    *) echo "Usage: tool/capture_screens.sh {play|iphone|ipad} {demo-on|demo-off|<slug>}" >&2
       exit 2 ;;
esac

[ -n "$action" ] || { echo "Second argument missing: a slug, or demo-on/demo-off." >&2; exit 2; }

RAW="$ROOT/store/$target/raw"

shot_android() {
    if [ "$(adb devices | grep -c "device$")" -eq 0 ]; then
        echo "No Android device or emulator. Start the Pixel_10_Pro AVD, or plug" >&2
        echo "the phone straight into the Mac rather than through a hub." >&2
        exit 1
    fi
    adb exec-out screencap -p > "$1"
}

shot_ios() {
    local dev="${3:-${ATOM_SIM_UDID:-booted}}"
    if ! xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
        echo "No booted iOS simulator. Boot one first, e.g." >&2
        echo "  xcrun simctl boot 'iPhone Air'" >&2
        exit 1
    fi
    if ! xcrun simctl io "$dev" screenshot --type=png "$1" >/dev/null 2>&1; then
        echo "simctl could not capture '$dev'. With more than one simulator" >&2
        echo "booted, pass a UDID: tool/capture_screens.sh <target> <slug> <udid>" >&2
        exit 1
    fi
}

demo() { adb shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }

case "$action" in
    demo-on)
        [ "$target" = play ] || { echo "demo mode is Android only." >&2; exit 2; }
        adb shell settings put global sysui_demo_allowed 1
        demo -e command enter
        demo -e command clock -e hhmm 0941
        demo -e command battery -e level 100 -e plugged false
        demo -e command network -e wifi show -e level 4
        demo -e command network -e mobile show -e datatype none -e level 4
        demo -e command notifications -e visible false
        echo "Status bar in demo mode: 09:41, full battery, no clutter."
        ;;
    demo-off)
        [ "$target" = play ] || { echo "demo mode is Android only." >&2; exit 2; }
        demo -e command exit
        echo "Status bar handed back to the device."
        ;;
    *)
        mkdir -p "$RAW"
        out="$RAW/$action.png"
        if [ "$target" = play ]; then shot_android "$out"; else shot_ios "$out" "" "${3:-}"; fi
        python3 -c "
from PIL import Image
im = Image.open('$out')
print(f'  $out  {im.width}x{im.height}')
"
        ;;
esac
