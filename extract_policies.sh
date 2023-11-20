#!/bin/bash

# Purpose: This Bash script accepts three parameters and performs Ranger policies 
# and roles extraction for all registered services using Ranger API.
#
# Usage: $0 <param1> <param2> <param3>
# <param1>: Ranger admin server name
# <param2>:	Ranger user name with admin rights
# <param3>: Ranger user password
#
# Example: $0 value1 value2 value3
#
# Author: Leonid Fedotov (lfedotov@cloudera.com)
# Version:	2.0
# Date: 5 October 2023


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
echo "Extracting Ranger policies from server $server, using user account $user."
#echo "Ranger server name: $server"
#echo "User name: $user"

# Creating output location
current_date=$(date +%Y-%m-%d_%H-%M)
policies_destination="./policies-$current_date"
services_destination="./services-$current_date"
roles_destination="./roles-$current_date"

mkdir $policies_destination
mkdir $services_destination
mkdir $roles_destination

#Extracting Ranger version
version=`curl -s -u $user:$password https://$server:6182/apidocs/swagger.json | grep version | head -1 | grep -o '[0-9.-]\+'`
#echo $version

#Today's date and time
today=`date '+%b %d, %Y %l:%M:%S %p'`
#echo $today

#Populating metadata 
meta1='  },'
meta2='    "Ranger apache version": "'; meta2+=$version ;meta2+='"'
meta3='    "Export time": "'; meta3+=$today; meta3+='",'
meta4='    "Exported by": "'; meta4+=$user; meta4+='",'
meta5='    "Host name": "';meta5+=$server; meta5+='",'
meta6='  "metaDataInfo": {'

#echo $meta1
#echo $meta2
#echo $meta3
#echo $meta4
#echo $meta5
#echo $meta6


# Extracting and parcing list of the services

curl -s -u $user:$password https://$server:6182/service/public/v2/api/service |  python -m json.tool > $services_destination/services.json
grep '"name":' $services_destination/services.json > $services_destination/services.list
sed -i 's/.*"cm\(.*\)",\?/cm\1/' $services_destination/services.list


# Extracting roles-to-groups mapping

echo ""
echo "Extracting roles-to-groups mapping all roles in the same file"
echo ""

curl -s -u $user:$password https://$server:6182/service/public/v2/api/roles |  python -m json.tool > $roles_destination/roles.json

# Replacing [ to { and ] to } in first and last lines
sed -i 's/^\[/{/' $roles_destination/roles.json
sed -i 's/^\]/}/' $roles_destination/roles.json

# Add metadata lines
sed -i '1a\
    "roles": [' $roles_destination/roles.json
sed -i "1a\\
${meta1}" $roles_destination/roles.json
sed -i "1a\\
${meta2}" $roles_destination/roles.json
sed -i "1a\\
${meta3}" $roles_destination/roles.json
sed -i "1a\\
${meta4}" $roles_destination/roles.json
sed -i "1a\\
${meta5}" $roles_destination/roles.json
sed -i "1a\\
${meta6}" $roles_destination/roles.json


# Add ] to the line before last
sed -i '$i\
]' $roles_destination/roles.json

# Extracting list of the roles names

curl -s -u $user:$password -X 'GET' -H 'accept: application/json' https://$server:6182/service/roles/roles/names | tr -d '[]"' | sed 's/,/\n/g' > $roles_destination/roles.list

# Extracting roles individually
echo ""
echo "Extracting roles individually"
echo ""

for role in `cat $roles_destination/roles.list`; do
echo ""
echo "Extracting role $role"
echo ""

curl -s -u $user:$password -X 'GET' -H 'accept: application/json' https://$server:6182/service/roles/roles/name/$role -o $roles_destination/$role.json
done

#Extracting all services individually

for service in `cat $services_destination/services.list`; 
do 
echo ""
echo "Extracting service $service"
echo ""
curl -s -u $user:$password https://$server:6182/service/public/v2/api/service/name/$service |  python -m json.tool  > $services_destination/service_$service.json
done


# Extracting policies for each service individually

for service in `cat $services_destination/services.list`; 
do 
echo ""
echo "Extracting policies for service $service"
echo ""
curl -s -u $user:$password "https://$server:6182/service/plugins/policies/exportJson?serviceName=$service&checkPoliciesExists=false" -o $policies_destination/$service.json


# Extracting individual policies for the service

policies_destination_individual="$policies_destination/$service-policies"
mkdir -p $policies_destination_individual

grep '"id":' $policies_destination/$service.json > $policies_destination_individual/policies.list
sed -i 's/[^0-9]//g' $policies_destination_individual/policies.list

echo ""
echo "Extracting individual policies for service $service"
echo ""


for policy in `cat $policies_destination_individual/policies.list`; 
do 
curl -s -u $user:$password "https://$server:6182/service/public/v2/api/policy/$policy" |  python -m json.tool > $policies_destination_individual/$policy.json
sed -i '1s/^/{\n/' $policies_destination_individual/$policy.json
sed -i '1a\
    "policies": [' $policies_destination_individual/$policy.json
sed -i '$s/$/\n]\n}/' $policies_destination_individual/$policy.json

done

done
