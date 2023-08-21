#!/usr/bin/env sh

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

#export MONITOR3="HDMI-2"


export SCREENPROFILE=$(autorandr | grep current | cut -d' ' -f1)

if [ $SCREENPROFILE == "3monitor" ]
then
    export MONITOR1=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | head -n 1)
    export MONITOR2=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | sed -n 2p)
    export MONITOR3=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | sed -n 3p)
    polybar bar &
    polybar second &
    polybar third
elif [ $SCREENPROFILE == "1monitor" ]
then
    export MONITOR1=$(xrandr -q | grep " connected" | cut -d ' ' -f1 | head -n 1)
    polybar bar 
fi


echo "Bars launched..."
