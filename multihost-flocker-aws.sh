#!/bin/bash

set -e

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

##### Docker Machine Setup

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    mha-consul

docker $(docker-machine config mha-consul) run -d \
    -p "8500:8500" \
    -h "consul" \
    progrium/consul -server -bootstrap

docker $(docker-machine config mha-consul) run -d \
    -p 3376:3376 -v /etc/docker/:/certs:ro swarm manage \
    --host=0.0.0.0:3376 \
    --tlsverify --tlscacert=/certs/ca.pem \
    --tlscert=/certs/server.pem \
    --tlskey=/certs/server-key.pem \
    --replication --advertise $(docker-machine ip mha-consul):3376 \
    consul://$(docker-machine ip mha-consul):8500

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    --engine-opt="cluster-store=consul://$(docker-machine ip mha-consul):8500" \
    --engine-opt="cluster-advertise=eth0:0" \
    mha-demo0

docker $(docker-machine config mha-demo0) run -d \
    -p 3376:3376 -v /etc/docker/:/certs:ro swarm manage \
    --host=0.0.0.0:3376 \
    --tlsverify --tlscacert=/certs/ca.pem \
    --tlscert=/certs/server.pem \
    --tlskey=/certs/server-key.pem \
    --replication --advertise $(docker-machine ip mha-demo0):3376 \
    consul://$(docker-machine ip mha-consul):8500

docker $(docker-machine config mha-demo0) run -d \
   --restart=always swarm join \
   --advertise=$(docker-machine ip mha-demo0):2376 \
   consul://$(docker-machine ip mha-consul):8500

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    --engine-opt="cluster-store=consul://$(docker-machine ip mha-consul):8500" \
    --engine-opt="cluster-advertise=eth0:0" \
    mha-demo1

docker $(docker-machine config mha-demo1) run -d \
   --restart=always swarm join \
   --advertise=$(docker-machine ip mha-demo1):2376 \
   consul://$(docker-machine ip mha-consul):8500

docker-machine create \
    -d amazonec2 \
    --amazonec2-security-group ${group_name} \
    --engine-opt="cluster-store=consul://$(docker-machine ip mha-consul):8500" \
    --engine-opt="cluster-advertise=eth0:0" \
    mha-demo2

docker $(docker-machine config mha-demo2) run -d \
   --restart=always swarm join \
   --advertise=$(docker-machine ip mha-demo2):2376 \
   consul://$(docker-machine ip mha-consul):8500

echo "Done!"
echo "Installing Flocker..."

# List only running mha-demo* nodes
aws ec2 describe-instances \
--filter Name=tag:Name,Values=mha-demo* Name=instance-state-code,Values=16 --output=json | \
  python create_flocker_inventory.py

# Install Flocker
# above creates ansible-inventory and agent.yml
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
  --key-file ${AWS_SSH_KEYPATH} \
  -i ./ansible_inventory \
  ./aws-flocker-installer.yml  \
  --extra-vars "flocker_agent_yml_path=${PWD}/agent.yml"

echo "Complete"
