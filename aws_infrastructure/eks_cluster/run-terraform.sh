#!/bin/bash

environment_name=$1
action=$2

if [ -z "$environment_name" ]; then
    echo "Need to include environment variable e.g. ./run-terraform.sh <environment> <plan>"
    exit 1
fi

if [ $action != "apply" ] && [ $action != "plan" ] && [ $action != "destroy" ]; then
    echo "You must provide an action (apply/plan/destroy) e.g. ./run-terraform.sh <environment> <plan>"
    exit 1
fi

vpc_name=${environment_name}-vpc
echo $vpc_name
vpc_id=`aws ec2 describe-vpcs --filter Name=tag:Name,Values=${vpc_name} --query 'Vpcs[*].VpcId' --output text`

if [ -z "$vpc_id" ]; then
    echo "Nothing to ${action}, no vpc exists!"
    exit 1
fi

private_security_group=`aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${environment_name}-private-securitygroup" --query 'SecurityGroups[*].GroupId' --output text`

if [ -z "$private_security_group" ]; then
    echo "No private security group exists, need this for Control Plane Security Group!"
    exit 1
fi

private_subnet=`aws ec2 describe-subnets --filters "Name=tag:Name,Values=${environment_name}-private-subnet" --query 'Subnets[*].SubnetId' --output text`
private_subnet_two=`aws ec2 describe-subnets --filters "Name=tag:Name,Values=${environment_name}-private-subnet2" --query 'Subnets[*].SubnetId' --output text`
public_subnet=`aws ec2 describe-subnets --filters "Name=tag:Name,Values=${environment_name}-public-subnet" --query 'Subnets[*].SubnetId' --output text`
public_subnet_two=`aws ec2 describe-subnets --filters "Name=tag:Name,Values=${environment_name}-public-subnet2" --query 'Subnets[*].SubnetId' --output text`

if [ -z "$private_subnet" ] || [ -z "$private_subnet_two" ] || [ -z "$public_subnet" ] || [ -z "$public_subnet_two" ]; then
    echo "Subnet information missing - all subnets needed (Private and Public)"
    exit 1
fi

terraform $action -var "environment_name=${environment_name}" -var "vpc_id=${vpc_id}" -var "private_security_group"=${private_security_group} \
-var "private_subnet"=${private_subnet} -var "private_subnet_two"=${private_subnet_two} -var "public_subnet"=${public_subnet} \
-var "public_subnet_two"=${public_subnet_two}

export node_instance_role=`terraform output node_instance_role`
export eks_service_role=`terraform output eks_service_role`
