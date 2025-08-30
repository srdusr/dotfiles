#!/bin/bash

killall -q xob
pkill -f manage-volume
pkill -f manage-brightness
pkill -f manage-microphone

"$HOME"/.config/xob/manage-volume | xob -s default &
"$HOME"/.config/xob/manage-brightness | xob -s default &
"$HOME"/.config/xob/manage-microphone | xob -s default &
