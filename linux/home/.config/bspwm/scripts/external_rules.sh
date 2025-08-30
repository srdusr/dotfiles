#!/bin/env bash
#
# external_rules_command
#
# Absolute path to the command used to retrieve rule consequences.
# The command will receive the following arguments: window ID, class
# name, instance name, and intermediate consequences. The output of
# that command must have the following format: key1=value1
# key2=value2 ...  (the valid key/value pairs are given in the
# description of the rule command).
#
#
# Rule
#    General Syntax
# 	   rule COMMANDS
#
#    Commands
# 	   -a, --add (<class_name>|*)[:(<instance_name>|*)] [-o|--one-shot]
# 	   [monitor=MONITOR_SEL|desktop=DESKTOP_SEL|node=NODE_SEL]
# 	   [state=STATE] [layer=LAYER] [split_dir=DIR] [split_ratio=RATIO]
# 	   [(hidden|sticky|private|locked|marked|center|follow|manage|focus|border)=(on|off)]
# 	   [rectangle=WxH+X+Y]
# 		   Create a new rule.
#
# 	   -r, --remove
# 	   ^<n>|head|tail|(<class_name>|*)[:(<instance_name>|*)]...
# 		   Remove the given rules.
#
# 	   -l, --list
# 		   List the rules.

# Programs to specific desktops
wid=$1
class=$2
instance=$3
consequences=$4

main() {
    case "$class" in
    firefox)
        if [ "$instance" = "Toolkit" ]; then
            echo "state=floating sticky=on"
        fi
        ;;
    Spotify)
        echo desktop=^5 follow=on focus=on
        ;;
    "")
        sleep 0.5

        wm_class=("$(xprop -id "$wid" | grep "WM_CLASS" | grep -Po '"\K[^,"]+')")

        class=${wm_class[-1]}

        [[ ${#wm_class[@]} == "2" ]] && instance=${wm_class[0]}

        [[ -n "$class" ]] && main
        ;;
    esac
}

main

# Allow floating windows over fullscreen
wid="$1"
class="$2"
instance="$3"
eval "$4"

[[ "$state" = floating ]] &&
    echo 'layer=above'
