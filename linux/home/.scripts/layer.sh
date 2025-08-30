#!/bin/bash

current_layer="$(bspc query -T -n | jq -r '.client.layer')"
case $1 in
    +|-)
        declare -A _layers=( [below]=0 [normal]=1 [above]=2 )
        layers=( below normal above )
        maxl=$(( ${#layers[@]} - 1 ))
        current_layer="$(bspc query -T -n | jq -r '.client.layer')"
        i=$(( ${_layers[$current_layer]} $1 1 ))
        if [[ $i -lt 0 ]]; then
            i=0
        elif [[ $i -gt $maxl ]]; then
            i=$maxl
        fi
        #cycle? nah
        #i=$(( (${_layers[$current_layer]} + ${#layers[@]} ${1} 1) % ${#layers[@]} ))
        new_layer="${layers[$i]}"
        ;;
    *)
        new_layer="$(bspc query -T -n | jq -r '.client.lastLayer')"
        ;;
esac
[[ "$current_layer" != "$new_layer" ]] && bspc node -l "$new_layer"
