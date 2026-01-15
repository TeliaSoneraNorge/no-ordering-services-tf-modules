#!/bin/bash

# Create artifacts directory if it doesn't exist
mkdir -p artifacts

# Loop through each directory in the current path
for dir in */; do
    # Remove trailing slash from directory name
    dir_name="${dir%/}"
    
    # Skip the artifacts directory itself
    if [ "$dir_name" == "artifacts" ]; then
        continue
    fi
    
    # Zip the directory and place it in artifacts
    (cd ${dir_name} && zip -r "../artifacts/${dir_name}.zip" . )
    
    echo "Packaged: ${dir_name}.zip"
done
