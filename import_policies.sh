#!/bin/bash

# Purpose: This script importing policies from a single JSON file.
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
file="$4"



# Perform file importing
    # Check if the input file exists
    if [ ! -f "$file" ]; then
        echo "Input file '$file' does not exist."
        usage
    fi

curl -k -v -i -X POST -H "Content-Type: multipart/form-data" -F "file=@./$file" -u $user:$password "https://$server:6182/service/plugins/policies/importPoliciesFromFile?isOverride=true"
	
    echo "File import complete."

