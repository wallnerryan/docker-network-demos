

# Multi-host Netowkring on UCP

- assumes you have run `multihost-flocker-aws-for-ucp.sh`
- you can do this manually for use `multihost-flocker-aws-add-ucp-multihostnet.sh`

## On the controller node

> Note: use the same <IP>s used during UCP install. 

```
docker run --rm -it --name ucp \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp engine-discovery \
  --controller <IP> [--controller <IP> ] \
  --host-address [<IP>] \
  --update
```

> Note: use multiple --controller commands if mulitple controllers for primar/secondary HA.

Example

```
docker $(docker-machine config mha-aws-consul) run --rm -it --name ucp-engine-disc \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker/ucp engine-discovery \
  --controller 52.87.163.88 \
  --host-address 52.87.163.88 \
  --update
```

Restart the daemon

```
docker-machine ssh mha-aws-consul sudo service docker restart
```

## Then on the rest of the controller replica's repeat the above steps.

## Then on the rest of the cluster/worker nodes, repeat the above steps.
