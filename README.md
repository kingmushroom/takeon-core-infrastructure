# takeon-eks

### How to build the EKS infrastructure for a User

##### Prerequisites
1. Make sure you are using the correct AWS_PROFILE, e.g - Sandbox. You can set this by running `export AWS_PROFILE=sandbox`.
2. Ask a member of the team for the values to populate the tfvars file.  Make sure you change 'user' variable to your name.
   *Example tfvars file:*

    my_ip = ""

    gov_wifi_ip = ""

    user = "user"

    accountID = ""

    cidr_public = ""

    cidr_public_two = ""

    cidr_private = ""

    cidr_private_two = ""

    cidr_node = ""


3. Run `init-tf.sh` in the aws_infrastructure directory from folders eks_cluster, rds and vpc by providing necessary parameters e.g bucket_name, file_name(in format git_repo/folder/env_name/user/terraform.tfstate), dynamodb_tab_name and region which will configure this git repo to store its terraform state in S3 bucket. Then ```terraform apply``` will put the latest state file in S3.  
   e.g. cd eks_cluster  
         ../init-tf.sh ${BUCKET_NAME} takeon-eks/eks_cluster/dev/${USER}/terraform.tfstate ${DYNAMODB_TAB_NAME} eu-west-2


##### Run Terraform
1. Run the script ./run-terraform.sh, passing in environment_name as the first parameter (The name of the VPC/Environment you want to deploy the cluster in)
   and the action as the second parameter (plan/apply/destroy)
2. The order you would normally do this in is:

    * `./run-terraform.sh <environment_name> <plan>` (Check the output to make sure the changes are what you expect).

    * `./run-terraform.sh <environment_name> <apply>` (To build/amend the infrastructure. Type Yes when prompted).

3. On the command line, run `aws eks --region eu-west-2 update-kubeconfig --name <cluster_name>` to update your ~/.kube/config file.
4. Run `kubectl apply -f aws_auth_cm.yaml` to allow the newly created nodes (EC2 instances) to join the cluster.
5. Test you can access your newly created cluster by running a simple `kubectl get all --all-namespaces`.
6. If successful, you can then deploy your applications to your cluster.
