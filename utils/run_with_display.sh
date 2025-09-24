#!/bin/bash

run_with_display() {
    output=$("$@" 2>&1)
    exit_status=$?

    if [[ $exit_status -ne 0 && ("$output" =~ "cannot open display" || "$output" =~ "DISPLAY environment variable is missing") ]]; then
        DISPLAY=:0 "$@"
    else
        echo "$output"
        return $exit_status
    fi
}

# Call this script with any command you want to run
command=$1
shift
run_with_display "$command" "$@"

