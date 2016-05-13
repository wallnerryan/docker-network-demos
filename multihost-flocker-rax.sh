#!/bin/bash

set -e

#### Set Up Environment

if [ -z $OS_API_KEY ]; then
    echo "Please supply your OS_API_KEY"
    exit 1
fi
if [ -z $OS_USERNAME ]; then
    echo "Please supply your OS_USERNAME"
    exit 1
fi

if [ -z $OS_REGION_NAME ]; then
    echo "Please supply your OS_REGION_NAME"
    exit 1
fi

##### Docker Machine Setup

# Setup 2 Machines
# 1) Consul for Service Discovery and Primary Swarm Manager
# 2) Agent node and Control Service for Flocker and Secondary Swarm Manager

docker-machine create \
    -d rackspace \
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
    -d rackspace \
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


# Create the rest of the machines as agent nodes.

# We have already created demo0, so minus 1
((AGENTS = ${CLUSTER_SIZE} - 1))
for i in `seq 1 ${AGENTS}`;
do
   docker-machine create \
       -d rackspace \
       --engine-opt="cluster-store=consul://$(docker-machine ip mha-consul):8500" \
       --engine-opt="cluster-advertise=eth0:0" \
       mha-demo${i}

   docker $(docker-machine config mha-demo${i}) run -d \
      --restart=always swarm join \
      --advertise=$(docker-machine ip mha-demo${i}):2376 \
      consul://$(docker-machine ip mha-consul):8500
done

echo "Done!"
echo "Installing Flocker..."

echo "Automatic flocker installation currently not supported"
# List only running mha-demo* nodes
#aws ec2 describe-instances \
#--filter Name=tag:Name,Values=mha-demo* Name=instance-state-code,Values=16 --output=json | \
#  python create_flocker_inventory.py

# Install Flocker
# above creates ansible-inventory and agent.yml
#ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
#  --key-file ${AWS_SSH_KEYPATH} \
#  -i ./ansible_inventory \
#  ./aws-flocker-installer.yml  \
#  --extra-vars "flocker_agent_yml_path=${PWD}/agent.yml"

echo "Complete"
