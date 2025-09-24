#!/bin/bash

# Check if the correct number of arguments are provided
if [[ $# -ne 2 ]]; then
    echo "Usage: checksum <file> <website>"
    exit 1
fi

FILE=$1
CHECKSUM_PAGE=$2

# Fetch the HTML content of the page
HTML_CONTENT=$(curl -s "$CHECKSUM_PAGE")

# Try searching for checksums with a more targeted approach, like matching a checksum pattern or look for files with checksum labels
CHECKSUM=$(echo "$HTML_CONTENT" | grep -oP '([a-f0-9]{64})' | head -n 1) # Try specifically looking for SHA256 checksum patterns

# Check if any checksum was found
if [[ -z "$CHECKSUM" ]]; then
    echo "Checksum not found on the page."
    exit 1
fi

# Calculate the checksum of the file locally
LOCAL_CHECKSUM=$(sha256sum "$FILE" | awk '{print $1}')

echo "Local checksum: $LOCAL_CHECKSUM"
echo "Remote checksum: $CHECKSUM"

# Compare the local checksum with the one from the website
if [[ "$LOCAL_CHECKSUM" == "$CHECKSUM" ]]; then
    echo "The checksums match! The file is verified."

else
    echo "The checksums do not match. The file may be corrupted or tampered with."
fi
