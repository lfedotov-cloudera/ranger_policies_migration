#!/bin/bash

## Purpose: This script importing policies from a single file.
#
# Usage: $0 server user password file
#
# Author: Leonid Fedotov (lfedotov@cloudera.com)
# Version:	1.0
# Date: 9 October 2023

# Function to display script usage
usage() {
    echo "Usage: $0 server user password file"
    echo ""
    exit 1
}

# Check if there are four parameters
if
 [ $# -ne 4 ]; then
 usage 
fi

# Initialize variables
server="$1"
user="$2"
password="$3"
folder="$4"


# Perform folder importing
# Check if the input folder exists
    if [ ! -d "$folder" ]; then
        echo "Input folder '$folder' does not exist."
        usage
    fi
    
    # Loop through files in the input folder and perform importing
    for role in `ls -1 "$folder"/*.json | grep -v roles.json`; do
        if [ -f "$role" ]; then
			curl  -k -v -X POST -H 'accept: application/json' -H 'Content-Type: application/json' -d @./$role -u $user:$password https://$server:6182/service/roles/roles
            echo "Imported: $file"
        fi
    done
    echo "Folder importing complete."
