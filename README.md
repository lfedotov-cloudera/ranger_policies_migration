# ranger_policies_migration

Several scripts have been developed to accomplish task: 

Tested and verified on FEPOC public Cloud deployment.
Was NOT tested on Privte Cloud
 


extract_policies.sh - main script which extracts all roles individually, all services and all policies for each service. Policies extracted as a single JSON file containing
 all policies for the service and indiviual policies (each into the separate JSON file). 


hive_path_map.sh - modify policies files to replace HDFS:// location to S3A:// location 


import_single_role.sh - importing single role from JSON file to target cluster 


import_roles.sh - importing all roles from the folder containing JSON files for roles 


import_singe_policy.sh - imports policy from the specified JSON file 


import_policies.sh - imports all policies from the specified JSON file, containing all policies for the service 


id_to_name_mapping.sh - generates CSV file which maps policy ID and policy name 


All scripts along with the sample outputs located in
https://jira.fepoc.com:8443/browse/CLOUDARCH-2105 


 


How to use the scripts: 


All scripts (except hive_path_map.sh) require a Ranger Admin server name, username with admin privileges and password for this user. All scripts use API calls to Ranger
 server for data exporting and importing. In addition, import scripts require full path name for the JSON file (role or policy). 


 


Sequence of execution: 


On a source cluster, run extract_policies.sh script. It requires parameters to be provided in a command line. It generates dated folders in a run directory for roles,
 services and policies. 


id_to_name_mapping.sh is a helper script, provide information on id <-> name relation for policies. It’s execution is optional. It also requires parameters to be provided
 in command line and produces dated folder with policies and CSV file 


When all policies extracted, script hive_path_map.sh needs to be run. It requires command line option, pointed to file or folder to convert. 


When all policies converted to S3A locations, resulting files needs to be transferred to target cluster. 


On target cluster import script needs to be executed. Depending on the needs, one of four import script needs to be used. It also requires parameters provided in the command
 line. 


NOTE: ROles must be imported BEFORE importing policies, otherwise policy may not be validated properly. 


 


Usage examples: 


 


./extract_policies.sh 


Usage: ./extract_policies.sh <param1> <param2> <param3> 


Description: This script accepts three parameters. 


<param1>: Ranger admin server name. 


<param2>: Ranger username with admin rights. 


<param3>: Ranger user password. 


 


./hive_path_map.sh 


Specify either -f for file conversion or -d for folder conversion, but not both. 


Usage: ./hive_path_map.sh [-f <input_file>] [-d <input_folder>] 


  -f <input_file>: Perform translation in a single file. 


  -d <input_folder>: Perform translation in all files in a folder. 


 


 


./mapping.sh 


Usage: ./mapping.sh <param1> <param2> <param3> 


Description: This script accepts three parameters. 


<param1>: Ranger admin server name. 


<param2>: Ranger username with admin rights. 


<param3>: Ranger user password. 


 


./import_roles.sh 


Usage: ./import_roles.sh server user password file 


 


./import_single_role.sh 


Usage: ./import_single_role.sh server user password file 


 


./import_policies.sh 


Usage: ./import_policies.sh server user password file 


 


./import_single_policy.sh 


Usage: ./import_single_policy.sh server user password file 


 


Comment:
 

Bofore running this cmd ,make sure to copy the original policy json payload to location where this .sh exists and  


run ./hive_path_map.sh -f <policy.json>, 

once the policy is converted with respective s3 paths ,execute the import_single_policy script. 

Both import_single_policy.sh and policy json need to be in the same directory. 

./import_single_policy.sh <RANGER HOST> <user> <password> <policy.json> 

