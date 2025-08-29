#!/bin/bash

# Get CPU average
getCPU=$[100-$(vmstat 1 2|tail -1|awk '{print $15}')]

# Grab the second line of the ouput produced by the command: free -g (displays output in Gb)
getMem=$(free -h | sed -n '2p')
getMemPct=$(free -g | sed -n '2p')

# Split the string in secondLine into an array
read -ra ADDR <<< "$getMem"
read -ra ADDRPct <<< "$getMemPct"

# Get the total RAM from arrays
totalRam="${ADDR[1]//[^0-9.0-9]/}"
totalRamPct="${ADDRPct[1]}"

# Get the used RAM from arrays
usedRam="${ADDR[2]//[^0-9.0-9]/}"
usedRamPct="${ADDRPct[2]}"

# Calculate and display the percentages
pct="$(($usedRamPct*100/$totalRamPct))"
usage="$usedRam/$totalRam"
#echo "cpu:$getCPU% | mem:$pct% ($usage""G)"
echo "Cpu:$getCPU% | Mem:$pct% |"

