#!/bin/bash

set -e

read -p "This script assumes you have run multihost-flocker-aws-for-ucp.sh, are you sure? [Yy]  " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

group_name=${MY_SEC_GROUP_NAME:="docker-networking"}
my_ip="$(wget -q -O- http://icanhazip.com)"

group_id="$(aws ec2 describe-security-groups --filters Name=group-name,Values=${group_name} --query 'SecurityGroups[*].{Name:GroupId}' | python aws_get_group_id.py)"
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 443 --cidr ${my_ip}/32 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 443 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol tcp --port 443 --cidr ${my_ip}/32 || true
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol tcp --port 443 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 2375 --cidr 0.0.0.0/0 || true
#alternative swarm port since docker already uses it.
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 23766 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol udp --port 4789 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol tcp --port 7946 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol udp --port 7946 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12376 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12379 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12380 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12381 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12382 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12383 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12384 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12385 --cidr 0.0.0.0/0 || true
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12386 --cidr 0.0.0.0/0 || true

PrivateIP=$(cat ~/.docker/machine/machines/mha-aws-consul/config.json | grep 'PrivateIPAddress' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

docker $(docker-machine config mha-aws-consul) run -d \
   --name ucp \
   -v /var/run/docker.sock:/var/run/docker.sock \
   docker/ucp install \
   --fresh-install \
   --swarm-port 23766 \
   --host-address=${PrivateIP} \
   --san ${PrivateIP} \
   --san $(docker-machine ip mha-aws-consul)

