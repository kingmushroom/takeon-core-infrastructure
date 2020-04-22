#!/bin/bash
set -e
if [ "$#" -ne 4 ]; then
  echo "Usage: Call this script with 4 parameters e.g. init-tf.sh bucket_name file_name(in format git_repo/folder/env_name/user/terraform.tfstate) dynamodb_tab_name region"
  exit 1
fi

terraform init \
-backend-config="bucket=$1" \
-backend-config="key=$2" \
-backend-config="dynamodb_table=$3" \
-backend-config="region=$4"

result=$?
if [ $result -eq 0 ]; then
  echo "Terraform Init of S3/DynamoDB setting for terraform state file has completed successfully"
  exit 0
else
  echo "Error in Terraform Init of S3/DynamoDB setting for terraform state file."
  exit 1
fi
