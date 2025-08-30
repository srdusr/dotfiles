#!/bin/bash

size=${2:-'10'}
dir=$1

# Find current window mode
is_tiled() {
bspc query -T -n | grep -q '"state":"tiled"'
}
# If the window is floating, move it
if ! is_tiled; then
#only parse input if window is floating,tiled windows accept input as is
        case "$dir" in
                west) switch="-w"
                sign="-"
                ;;
                east) switch="-w"
                sign="+"
                ;;
                north) switch="-h"
                sign="-"
                ;;
                south) switch="-h"
                sign="+"
                ;;
                esac
 xdo resize ${switch} ${sign}${size}

# Otherwise, window is tiled: switch with window in given direction
else
     case "$dir" in
                west) bspc node @west -r -$size || bspc node @east -r -${size}
                ;;
                east) bspc node @west -r +$size || bspc node @east -r +${size}
                ;;
                north) bspc node @south -r -$size || bspc node @north -r -${size}
                ;;
                south) bspc node @south -r +$size || bspc node @north -r +${size}
                ;;
                esac
fi

##!/bin/bash
#
#[ "$#" -eq 3 ] || { echo "Needs exactly three arguments."; exit 1; }
#
#motion="$1"
#direction="$2"
#size="$3"
#
#if [ "$motion" = 'expand' ]; then
#	# These expand the window's given side
#	case "$direction" in
#		north) bspc node -z top 0 -"$size" ;;
#		east) bspc node -z right "$size" 0 ;;
#		south) bspc node -z bottom 0 "$size" ;;
#		west) bspc node -z left -"$size" 0 ;;
#	esac
#else
#	# These contract the window's given side
#	case "$direction" in
#		north) bspc node -z top 0 "$size" ;;
#		east) bspc node -z right -"$size" 0 ;;
#		south) bspc node -z bottom 0 -"$size" ;;
#		west) bspc node -z left "$size" 0 ;;
#	esac
#fi
