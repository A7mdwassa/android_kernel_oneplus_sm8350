#!/bin/bash
echo "Enter File Path: "
read FILE
# Always open the original file
mousepad "$FILE" &

# If the path contains ".rej", also open the version without ".rej"
if [[ "$FILE" == *".rej"* ]]; then
    FILE_NO_REJ="${FILE/.rej/}"
    mousepad "$FILE_NO_REJ" &
fi
