#!/bin/bash

# This script handles rotation of the screen and related input devices automatically
# using the output of the monitor-sensor command (part of the iio-sensor-proxy package)
# for sway.
# The target screen and input device names should be configured in the below variables.
# Note: input devices using the libinput driver (e.g. touchscreens) should be included
# in the WAYLANDINPUT array.  
#
# You can get a list of input devices with the `swaymsg -t output` command.
#
# This scritp was frok from https://gitlab.com/snippets/1793649 by Fishonadish 


SCREEN="eDP-1"
WAYLANDINPUT=("11551:355:hid-over-i2c_2D1F:0163_Stylus"
    "0:0:Atmel_maXTouch_Touchscreen"
    "0:0:Atmel_maXTouch_Touchpad")


function rotate_ms {
    case $1 in
        "normal")
            SUBPIXEL="rgb"
            rotate 0
            ;;
        "right-up")
            SUBPIXEL="vbgr"
            rotate 90
            ;;
        "bottom-up")
            SUBPIXEL="bgr"
            rotate 180
            ;;
        "left-up")
            SUBPIXEL="vrgb"
            rotate 270
            ;;
    esac
}

function rotate {

    TARGET_ORIENTATION=$1

    echo "Rotating to" $TARGET_ORIENTATION " subpixel rendering " $SUBPIXEL

    swaymsg output $SCREEN transform $TARGET_ORIENTATION subpixel $SUBPIXEL

    for i in "${WAYLANDINPUT[@]}" 
    do
        swaymsg input "$i" map_to_output "$SCREEN"
    done

}

while IFS='$\n' read -r line; do
    rotation="$(echo $line | sed -En "s/^.*orientation changed: (.*)/\1/p")"
    [[ !  -z  $rotation  ]] && rotate_ms $rotation
done < <(stdbuf -oL monitor-sensor)

