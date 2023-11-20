#!/bin/bash

# Purpose: This script translates HDFS paths to S3A paths in either a single file or all files in a folder.
#
# Usage: $0 [-f <input_file>] [-d <input_folder>]"
#   -f <input_file>: Perform translation in a single file."
#   -d <input_folder>: Perform translation in all files in a folder."
#
# Example: $0 -f <file_name>
# Example: $0 -d <folder_name>
#
# Author: Leonid Fedotov (lfedotov@cloudera.com)
# Version:	1.0
# Date: 6 October 2023


# Initialize variables
file_conversion=false
folder_conversion=false

# Function to display script usage
usage() {
    echo "Usage: $0 [-f <input_file>] [-d <input_folder>]"
    echo "  -f <input_file>: Perform translation in a single file."
    echo "  -d <input_folder>: Perform translation in all files in a folder."
    exit 1
}

# Parse command-line options
while getopts ":f:d:" opt; do
    case $opt in
        f)
            input_file="$OPTARG"
            file_conversion=true
            ;;
        d)
            input_folder="$OPTARG"
            folder_conversion=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Check for the correct usage of options
if [[ "$file_conversion" == true && "$folder_conversion" == true ]] || [[ "$file_conversion" == false && "$folder_conversion" == false ]]; then
    echo "Specify either -f for file conversion or -d for folder conversion, but not both."
    usage
fi

# Perform file conversion
if [ "$file_conversion" == true ]; then
    # Check if the input file exists
    if [ ! -f "$input_file" ]; then
        echo "Input file '$input_file' does not exist."
        usage
    fi
    
    # Use sed for inline conversion in the file
    sed -i 's|hdfs://nameservice1|s3a://fepoc-dev-dv-e1-edh-s3s-workload-cdp-001/data/warehouse/tablespace/external/hive|g' "$input_file"
    
    echo "File conversion complete."
fi

# Perform folder conversion
if [ "$folder_conversion" == true ]; then
    # Check if the input folder exists
    if [ ! -d "$input_folder" ]; then
        echo "Input folder '$input_folder' does not exist."
        usage
    fi
    
    # Loop through files in the input folder and perform inline sed conversion
    for file in "$input_folder"/*.json; do
        if [ -f "$file" ]; then
            # Use sed for inline conversion in each file
            sed -i 's|hdfs://nameservice1|s3a://fepoc-dev-dv-e1-edh-s3s-workload-cdp-001/data/warehouse/tablespace/external/hive|g' "$file"
            echo "Converted: $file"
        fi
    done
    
    echo "Folder conversion complete."
fi
