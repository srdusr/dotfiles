#!/bin/bash

# Pulls CPU temps, averages them, and outputs them

count=0
sum=0.0

# Iterate over each temperature reading
for temp in "$(sensors | grep "^Core" | grep -e '+.*C' | cut -f 2 -d '+' | cut -f 1 -d ' ' | sed 's/°C//')"; do
    sum=$(echo "$sum + $temp" | bc)
    ((count++))
done

# Calculate the average
avg=$(echo "scale=0; $sum / $count" | bc)

# Output the average temperature without decimal points
echo " ${avg%.*}°C"
