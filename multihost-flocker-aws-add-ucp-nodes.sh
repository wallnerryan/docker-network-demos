#!/bin/bash

set -e

#### Set Up Environment

if [ -z $UCP_FINGERPRINT ]; then
    echo "Please supply your UCP_FINGERPRINT"
    exit 1
fi

export CLUSTER_SIZE=${MY_CLUSTER_SIZE:=3}

# assumes you have run `multihost-flocker-aws-add-ucp-control.sh` for controller
((AGENTS = ${CLUSTER_SIZE} - 1))
for i in `seq 0 ${AGENTS}`;
do
   docker $(docker-machine config mha-aws-demo${i}) run -d \
      --name ucp \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e UCP_ADMIN_USER=admin -e UCP_ADMIN_PASSWORD=orca \
      docker/ucp join \
      --swarm-port 23766 \
      --fresh-install \
      --san $(docker-machine ip mha-aws-demo${i}) \
      --host-address $(docker-machine ip mha-aws-demo${i}) \
      --url https://$(docker-machine ip mha-aws-consul) \
      --fingerprint ${UCP_FINGERPRINT}
done

echo "Done!"
