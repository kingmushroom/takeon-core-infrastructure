# Creating RDS

##### Prerequisites
1. Make sure you change 'user' variable to your name.
   *Example tfvars file:*

user='user'

2. Run `terraform init` in the aws_infrastructure directory.

##### Run Terraform
1. Run the script ./run-terraform.sh, passing in environment_name as the first parameter (The name of the VPC/Environment you want to deploy the cluster in)
   and the action as the second parameter (plan/apply/destroy)
2. The order you would normally do this in is:

    * `./run-terraform.sh <environment_name> <plan>` (Check the output to make sure the changes are what you expect).

    * `./run-terraform.sh <environment_name> <apply>` (To build/amend the infrastructure. Type Yes when prompted).

##### Databse Credentials
Note the username & password which will be printed in the terminal when the script is being executed.