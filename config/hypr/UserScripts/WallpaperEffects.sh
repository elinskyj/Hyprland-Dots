#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Wallpaper Effects using ImageMagick (SUPER SHIFT W)

# Variables
terminal=kitty
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
rofi_theme="~/.config/rofi/config-wallpaper-effect.rasi"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=30
TYPE="wipe"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Define ImageMagick effects
declare -A effects=(
    ["No Effects"]="no-effects"
    ["Black & White"]="convert $current_wallpaper -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
    ["Blurred"]="convert $current_wallpaper -blur 0x10 $wallpaper_output"
    ["Charcoal"]="convert $current_wallpaper -charcoal 0x5 $wallpaper_output"
    ["Edge Detect"]="convert $current_wallpaper -edge 1 $wallpaper_output"
    ["Emboss"]="convert $current_wallpaper -emboss 0x5 $wallpaper_output"
    ["Frame Raised"]="convert $current_wallpaper +raise 150 $wallpaper_output"
    ["Frame Sunk"]="convert $current_wallpaper -raise 150 $wallpaper_output"
    ["Negate"]="convert $current_wallpaper -negate $wallpaper_output"
    ["Oil Paint"]="convert $current_wallpaper -paint 4 $wallpaper_output"
    ["Posterize"]="convert $current_wallpaper -posterize 4 $wallpaper_output"
    ["Polaroid"]="convert $current_wallpaper -polaroid 0 $wallpaper_output"
    ["Sepia Tone"]="convert $current_wallpaper -sepia-tone 65% $wallpaper_output"
    ["Solarize"]="convert $current_wallpaper -solarize 80% $wallpaper_output"
    ["Sharpen"]="convert $current_wallpaper -sharpen 0x5 $wallpaper_output"
    ["Vignette"]="convert $current_wallpaper -vignette 0x3 $wallpaper_output"
    ["Vignette-black"]="convert $current_wallpaper -background black -vignette 0x3 $wallpaper_output"
    ["Zoomed"]="convert $current_wallpaper -gravity Center -extent 1:1 $wallpaper_output"
)

# Function to apply no effects
no-effects() {
    swww img -o "$focused_monitor" "$wallpaper_current" $SWWW_PARAMS &&
    wait $!
    wallust run "$wallpaper_current" -s &&
    wait $!
    # Refresh rofi, waybar, wallust palettes
	sleep 2
	"$SCRIPTSDIR/Refresh.sh"

    notify-send -u low -i "$iDIR/ja.png" "No wallpaper" "effects applied"
    # copying wallpaper for rofi menu
    cp "$wallpaper_current" "$wallpaper_output"
}

# Function to run rofi menu
main() {
    # Populate rofi menu options
    options=("No Effects")
    for effect in "${!effects[@]}"; do
        [[ "$effect" != "No Effects" ]] && options+=("$effect")
    done

    choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -i -config $rofi_theme)

    # Process user choice
    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "No Effects" ]]; then
            no-effects
        elif [[ "${effects[$choice]+exists}" ]]; then
            # Apply selected effect
            notify-send -u normal -i "$iDIR/ja.png"  "Applying:" "$choice effects"
            eval "${effects[$choice]}"

            sleep 1
            swww img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &

            sleep 2
  
            wallust run "$wallpaper_output" -s &
            sleep 1
            # Refresh rofi, waybar, wallust palettes
            "${SCRIPTSDIR}/Refresh.sh"
            notify-send -u low -i "$iDIR/ja.png" "$choice" "effects applied"
        else
            echo "Effect '$choice' not recognized."
        fi
    fi
}

# Check if rofi is already running and kill it
if pidof rofi > /dev/null; then
    pkill rofi
fi

main

sleep 1
# Check if user selected a wallpaper
if [[ -n "$choice" ]]; then
    sddm_sequoia="/usr/share/sddm/themes/sequoia_2"
    if [ -d "$sddm_sequoia" ]; then
        notify-send -i "$iDIR/ja.png" "Set wallpaper" "as SDDM background?" \
            -t 10000 \
            -A "yes=Yes" \
            -A "no=No" \
            -h string:x-canonical-private-synchronous:wallpaper-notify

        # Wait for user input using dbus-monitor
        dbus-monitor "interface='org.freedesktop.Notifications',member='ActionInvoked'" |
        while read -r line; do
          if echo "$line" | grep -q "yes"; then
            $terminal -e bash -c "echo 'Enter your password to set wallpaper as SDDM Background'; \
            sudo cp -r $wallpaper_output '$sddm_sequoia/backgrounds/default' && \
            notify-send -i '$iDIR/ja.png' 'SDDM' 'Background SET'"
            break
          elif echo "$line" | grep -q "no"; then
            echo "Wallpaper not set as SDDM background. Exiting."
            break
          fi
        done &
    fi
fi
