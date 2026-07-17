#!/usr/bin/env bash
# Clipboard bridge: X11 <-> Wayland
# Required: xclip, wl-clipboard

# Wayland → X11 (watch-based, efficient)
wl-paste --watch xclip -selection clipboard 2>/dev/null &

# X11 → Wayland (polling, no watch equivalent for X11)
(
    last=""
    while true; do
        current=$(xclip -o -selection clipboard 2>/dev/null) || true
        if [ "$current" != "$last" ] && [ -n "$current" ]; then
            printf '%s' "$current" | wl-copy --type text/plain 2>/dev/null
            last="$current"
        fi
        sleep 0.3
    done
) &

wait
