#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
#if [ "$1" == "light" ]
#then
#	polybar -c $HOME/.config/polybar/bars/light-config nord-top &
#	polybar -c $HOME/.config/polybar/bars/light-config nord-down &
#else
#	polybar -c $HOME/.config/polybar/bars/dark-config nord-top &
#	polybar -c $HOME/.config/polybar/bars/dark-config nord-down &
#fi
export SCREENPROFILE=$(autorandr | grep current | cut -d' ' -f1)

if [ $SCREENPROFILE == "3monitor" ] || [ $SCREENPROFILE == "3monitorNvidia" ]
then
    export MONITOR1=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | head -n 1)
    export MONITOR2=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | sed -n 2p)
    export MONITOR3=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | sed -n 3p)
	polybar -c $HOME/.config/polybar/bars/dark-config nord-top &
	polybar -c $HOME/.config/polybar/bars/dark-config nord-top-second &
	polybar -c $HOME/.config/polybar/bars/dark-config nord-top-third &
	polybar -c $HOME/.config/polybar/bars/dark-config nord-down &
elif [ $SCREENPROFILE == "1monitor" ]
then
	polybar -c $HOME/.config/polybar/bars/dark-config nord-top &
	polybar -c $HOME/.config/polybar/bars/dark-config nord-down &
fi

echo "Bars launched..."
