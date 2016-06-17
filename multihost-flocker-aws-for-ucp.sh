#!/bin/bash

set -e

# The difference with this script is that is doesnt set up swarm or consul.
# this is deffered to the scripts multihost-flocker-aws-add-ucp-control.sh and
# multihost-flocker-aws-add-ucp-nodes.sh

#### Set Up Environment

if [ -z $AWS_ACCESS_KEY_ID ]; then
    echo "Please supply your AWS_ACCESS_KEY_ID"
    exit 1
fi
if [ -z $AWS_SECRET_ACCESS_KEY ]; then
    echo "Please supply your AWS_ACCESS_KEY_ID"
    exit 1
fi
group_name=${MY_SEC_GROUP_NAME:="docker-networking"}
my_ip="$(wget -q -O- http://icanhazip.com)"
export AWS_AMI=${MY_AWS_AMI:="ami-fce3c696"}
export AWS_DEFAULT_REGION=${MY_AWS_DEFAULT_REGION:="us-east-1"}
# This is my default VPC, yours will be different
export AWS_VPC_ID=${MY_AWS_VPC_ID:="vpc-5d1c3539"}
export AWS_INSTANCE_TYPE=${MY_AWS_INSTANCE_TYPE:="m3.large"}
export AWS_SSH_USER=${MY_AWS_SSH_USER:="ubuntu"}
export AWS_ZONE=${MY_AWS_ZONE:="c"}
export CLUSTER_SIZE=${MY_CLUSTER_SIZE:=3}

#### Set up Security Group in AWS

aws ec2 create-security-group --group-name ${group_name} --vpc-id ${AWS_VPC_ID} --description "A Security Group for Docker Networking"
# Permit SSH, required for Docker Machine
group_id="$(aws ec2 describe-security-groups --filters Name=group-name,Values=${group_name} --query 'SecurityGroups[*].{Name:GroupId}' | python aws_get_group_id.py)"
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 22 --cidr ${my_ip}/32
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 2376 --cidr 0.0.0.0/0
# Permit Serf ports for discovery
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol udp --port 7946 --cidr 0.0.0.0/0
# Permit Consul HTTP API
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 8500 --cidr 0.0.0.0/0
# Permit VXLAN
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol udp --port 4789 --cidr 0.0.0.0/0
# Permit Flocker
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 4524 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 4523 --cidr 0.0.0.0/0
#Swarm Manager 
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 3376 --cidr 0.0.0.0/0
#Moby App 
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 80 --cidr 0.0.0.0/0

##### Docker Machine Setup

# Setup 2 Machines
# 1) Consul for Service Discovery and Primary Swarm Manager
# 2) Agent node and Control Service for Flocker and Secondary Swarm Manager

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    mha-aws-consul

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    mha-aws-demo0

# Create the rest of the machines as agent nodes.

# We have already created demo0, so minus 1
((AGENTS = ${CLUSTER_SIZE} - 1))
for i in `seq 1 ${AGENTS}`;
do
   docker-machine create \
       -d amazonec2 \
       --amazonec2-security-group ${group_name} \
       mha-aws-demo${i}
done

echo "Done!"
echo "Installing Flocker..."

# List only running mha-aws-demo* nodes
aws ec2 describe-instances \
--filter Name=tag:Name,Values=mha-aws-demo* Name=instance-state-code,Values=16 --output=json | \
  python create_flocker_inventory.py

# Install Flocker
# above creates ansible-inventory and agent.yml
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
  --key-file ${AWS_SSH_KEYPATH} \
  -i ./ansible_inventory \
  ./aws-flocker-installer.yml  \
  --extra-vars "flocker_agent_yml_path=${PWD}/agent.yml"

echo "Complete"
