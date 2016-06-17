#!/bin/bash

set -e

read -p "Make sure you export UCP_FINGERPRINT from the controller, continue? [Yy]  " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

#### Set Up Environment

if [ -z "$UCP_FINGERPRINT" ]; then
    echo "Please supply your UCP_FINGERPRINT"
    exit 1
fi

export CLUSTER_SIZE=${MY_CLUSTER_SIZE:=3}

# assumes you have run `multihost-flocker-aws-add-ucp-control.sh` for controller
((AGENTS = ${CLUSTER_SIZE} - 1))
for i in `seq 0 ${AGENTS}`;
do
    PrivateIP=$(cat ~/.docker/machine/machines/mha-aws-demo${i}/config.json | grep 'PrivateIPAddress' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    ControlPrivateIP=$(cat ~/.docker/machine/machines/mha-aws-consul/config.json | grep 'PrivateIPAddress' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    docker $(docker-machine config mha-aws-demo${i}) run -d \
      --name ucp \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e UCP_ADMIN_USER=admin -e UCP_ADMIN_PASSWORD=orca \
      docker/ucp join \
      --swarm-port 23766 \
      --fresh-install \
      --san $(docker-machine ip mha-aws-demo${i}) \
      --san ${PrivateIP} \
      --host-address ${PrivateIP} \
      --url https://${ControlPrivateIP} \
      --fingerprint ${UCP_FINGERPRINT}
done

echo "Done!"
