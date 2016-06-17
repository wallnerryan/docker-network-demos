#!/bin/bash

set -e

#### Set Up Environment

ControlPrivateIP=$(cat ~/.docker/machine/machines/mha-aws-consul/config.json | grep 'PrivateIPAddress' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
docker $(docker-machine config mha-aws-consul) run --rm -it \
  --name ucp-engine-disc \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp engine-discovery \
  --controller ${ControlPrivateIP} \
  --host-address ${ControlPrivateIP} \
  --update

# wait for initialization
sleep 10

docker-machine ssh mha-aws-consul sudo service docker restart

# give time for daemon and all UCP containers to restart.
sleep 30

export CLUSTER_SIZE=${MY_CLUSTER_SIZE:=3}

# assumes you have run `multihost-flocker-aws-add-ucp-control.sh` for controller
((AGENTS = ${CLUSTER_SIZE} - 1))
for i in `seq 0 ${AGENTS}`;
do
   PrivateIP=$(cat ~/.docker/machine/machines/mha-aws-demo${i}/config.json | grep 'PrivateIPAddress' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
   docker $(docker-machine config mha-aws-demo${i}) run --rm -it --name ucp-engine-disc \
   -v /var/run/docker.sock:/var/run/docker.sock \
   docker/ucp engine-discovery \
   --controller ${ControlPrivateIP} \
   --host-address ${PrivateIP} \
   --update

   # wait for initialization
   sleep 10

   docker-machine ssh mha-aws-demo${i} sudo service docker restart

   # give time for daemon to restart.
   sleep 5
done

echo "Done!"
