#!/bin/bash

set -e

read -p "This script assumes you have run multihost-flocker-aws.sh, are you sure? [Yy]  " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

my_ip="$(wget -q -O- http://icanhazip.com)"

group_id="$(aws ec2 describe-security-groups --filters Name=group-name,Values=${group_name} --query 'SecurityGroups[*].{Name:GroupId}' | python aws_get_group_id.py)"
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 443 --cidr ${my_ip}/32
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol tcp --port 443 --cidr ${my_ip}/32
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 2376 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 2375 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol udp --port 4789 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol udp --port 4789 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol tcp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol udp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id ${group_id} --protocol udp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12376 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12379 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12380 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12381 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12382 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12383 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12384 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12385 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${group_id} --protocol tcp --port 12386 --cidr 0.0.0.0/0


docker $(docker-machine config mha-aws-consul) run -d \
   --rm --name ucp \
   -v /var/run/docker.sock:/var/run/docker.sock \
   docker/ucp install \
   --fresh-install \
   --host-address=$(docker-machine ip mha-aws-consul) \
   --san $(docker-machine ip mha-aws-consul)"


