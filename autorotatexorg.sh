
#!/bin/bash

# Auto-rotate screen + input devices under Xorg using monitor-sensor

SCREEN="eDP-1"

# Detect all input device IDs that support rotation
function detect_input_devices {
    XINPUT_DEVICES=()
    while IFS= read -r id; do
        # Check for Coordinate Transformation Matrix
        if ! xinput list-props "$id" 2>/dev/null | grep -q "Coordinate Transformation Matrix"; then
            continue
        fi

        # Check device type: only include pointers (skip keyboards)
        TYPE=$(xinput list "$id" | grep -oP 'slave\s+pointer')
        [[ -z "$TYPE" ]] && continue

        # Optional: check for absolute axes to ensure it's touch/tablet
        if xinput list-props "$id" 2>/dev/null | grep -Eq 'Abs X|Abs Y|Coordinate Transformation Matrix'; then
            XINPUT_DEVICES+=("$id")
        fi
    done < <(xinput --list --id-only)
}

# Rotate each input device by ID
for ID in "${XINPUT_DEVICES[@]}"; do
    xinput set-prop "$ID" "Coordinate Transformation Matrix" $MATRIX
done

# Function: Rotate screen & inputs
function rotate {
    TARGET_ORIENTATION=$1
    echo "Rotating screen $SCREEN to $TARGET_ORIENTATION"

    case $TARGET_ORIENTATION in
        "normal")
            XRANDR_ROT="normal"
            MATRIX="1 0 0 0 1 0 0 0 1"
            ;;
        "right-up")
            XRANDR_ROT="right"
            MATRIX="0 1 0 -1 0 1 0 0 1"
            ;;
        "bottom-up")
            XRANDR_ROT="inverted"
            MATRIX="-1 0 1 0 -1 1 0 0 1"
            ;;
        "left-up")
            XRANDR_ROT="left"
            MATRIX="0 -1 1 1 0 0 0 0 1"
            ;;
    esac

    # Rotate the display
    xrandr --output $SCREEN --rotate $XRANDR_ROT

    

    # Rotate each detected input device
    for ID in "${XINPUT_DEVICES[@]}"; do
	xinput set-prop "$ID" "Coordinate Transformation Matrix" $MATRIX
    done
}

# Detect input devices at start
detect_input_devices
echo "Detected input devices for rotation:"
printf '%s\n' "${XINPUT_DEVICES[@]}"

# Monitor sensor events
while IFS='$\n' read -r line; do
    rotation="$(echo $line | sed -En "s/^.*orientation changed: (.*)/\1/p")"
    [[ ! -z $rotation ]] && rotate $rotation
done < <(stdbuf -oL monitor-sensor)

