#!/bin/env bash

#instance=$3
#[!-z"$3"] && xdo raise -a polybar-bottom_LVDS-1
#[!-z"$3"] && xdo below -a polybar-bottom_LVDS-1 -t $(xdo id -N Bspwm -n root)


#bspc subscribe node_state | while read -r _ _ _ _ state flag; do
#  if [[ "$state" != fullscreen ]]; then continue; fi
#  if [[ "$flag" == on ]]; then
#    xdo lower -N Plank
#  else
#    xdo raise -N Plank
#  fi
#done &
#
#eval $4
#bspc query -N -d ${desktop:-focused} -n .fullscreen >/dev/null &&
#    echo layer=above


#bspc subscribe node_state | while read -r _ _ _ _ state flag; do
#  if [[ "$state" != fullscreen ]]; then continue; fi
#  if [[ "$flag" == on ]]; then
#    xdo lower -a polybar-bottom_LVDS-1
#  else
#    xdo raise -a polybar-bottom_LVDS-1
#  fi
#done &

# Allow any type of window to ignore fullscreen windows (allow fullscreen to
# stay)
wid="$1"
class="$2"
instance="$3"
eval "$4"

[[ "$state" = floating ]] \
    && echo 'layer=above'
