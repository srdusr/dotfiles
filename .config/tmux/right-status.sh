#!/bin/bash

function memory-usage() {
    if [ "$(which bc)" ]; then
        # Display used, total, and percentage of memory using the free command.
        read used total <<< $(free -m | awk '/Mem/{printf $2" "$3}')
        # Calculate the percentage of memory used with bc.
        percent=$(bc -l <<< "100 * $total / $used")
        # Feed the variables into awk and print the values with formating.
        awk -v u=$used -v t=$total -v p=$percent 'BEGIN {printf "%s/%s Mem %.1f% ", t, u, p}'
    fi
}

function main() {
    # Comment out any function you do not need. 
    memory-usage
}

# Calling the main function which will call the other functions.
main
