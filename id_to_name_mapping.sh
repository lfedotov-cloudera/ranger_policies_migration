#!/bin/bash

# Purpose: This Bash script accepts three parameters and performs Ranger policies 
# for Hive service and maps policy ID to policy Name to a CSV file.
#
# Usage: $0 <param1> <param2> <param3>
# <param1>: Ranger admin server name
# <param2>:	Ranger user name with admin rights
# <param3>: Ranger user password
#
# Example: $0 value1 value2 value3
#
# Author: Leonid Fedotov (lfedotov@cloudera.com)
# Version:	1.0
# Date: 12 October 2023


# Function to display usage help
usage()
 { echo "Usage: $0 <param1> <param2> <param3>"
echo "Description: This script accepts three parameters."
echo " <param1>: Ranger admin server name."
echo " <param2>: Ranger user name with admin rights."
echo " <param3>: Ranger user password."
exit 1 
} 


# Check if there are three parameters
if
 [ $# -ne 3 ]; then
 usage 
fi

server="$1"
user="$2"
password="$3"

# Your script logic here using the parameters
echo "Extracting Ranger policies for Hive from server $server, using user account $user."
#echo "Ranger server name: $server"
#echo "User name: $user"

# Creating output location
current_date=$(date +%Y-%m-%d_%H-%M)
destination="./mapping-$current_date"

mkdir $destination

service="cm_hive"
curl -s -u $user:$password "https://$server:6182/service/plugins/policies/exportJson?serviceName=$service&checkPoliciesExists=false" -o $destination/$service.json


# Extracting individual policies for the service


grep '"id":' $destination/$service.json > $destination/policies.list
sed -i 's/[^0-9]//g' $destination/policies.list

echo ""
echo "Extracting individual policies for service $service"
echo ""


for policy in `cat $destination/policies.list`; 
do 
curl -s -u $user:$password "https://$server:6182/service/public/v2/api/policy/$policy" |  python -m json.tool > $destination/$policy.json
sed -i '1s/^/{\n/' $destination/$policy.json
sed -i '1a\
    "policies": [' $destination/$policy.json
sed -i '$s/$/\n]\n}/' $destination/$policy.json

done

# Function to extract a field's value from JSON
extract_field() {
  local field="$1"
  local data="$2"
  local result=""
  # Use grep and sed to extract the field value
  result=$(echo "$data" | grep -o "\"$field\": *\"[^\"]*\"" | sed 's/"[^"]*": "\(.*\)"/\1/')
  echo "$result"
}

extract_numeric_field() {
  local field="$1"
  local data="$2"
  local result=""
  # Use grep and sed to extract the numeric field value
  result=$(echo "$data" | grep -o "\"$field\": *[0-9]*" | sed 's/"[^"]*": *\([0-9]*\)/\1/')
  echo "$result"
}

for input_file in `ls $destination | grep '^[0-9]*\.json$'`; do

# Read JSON data from the input file
json_data=$(cat "$destination/$input_file")

# Extract "name" and "id" fields
id=$(extract_numeric_field "id" "$json_data")
name=$(extract_field "name" "$json_data")

echo -e "$id|$name" >> $destination/id_to_name_map.csv

done
