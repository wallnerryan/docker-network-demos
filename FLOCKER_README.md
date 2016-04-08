

# HOW TO

Install Docker Machine

```
export MY_AWS_AMI="ami-fce3c696"
export MY_AWS_DEFAULT_REGION="us-east-1"
export MY_AWS_VPC_ID="vpc-5d1c3539"
export MY_AWS_INSTANCE_TYPE="m3.large"
export MY_AWS_SSH_USER="ubuntu"
export MY_SEC_GROUP_NAME="ryan-test-sec-group"
export MY_AWS_ZONE="c"
export AWS_SSH_KEYPATH="/Users/wallnerryan/.ssh/id_rsa"
```

### Install Tools

```
pip install ansible
pip install https://clusterhq-archive.s3.amazonaws.com/python/Flocker-1.11.0-py2-none-any.whl
ansible-galaxy install ClusterHQ.flocker -p ./roles
```

### Make sure `docker-machine` and `aws` cli are installed
```
$:-> docker-machine --version
docker-machine version 0.6.0, build e27fb87

(virtualenv-aws)$:-> aws --version
aws-cli/1.9.1 Python/2.7.10 Darwin/15.2.0 botocore/1.3.1
```

### Set Credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

### Run the installation

```
./multihost-flocker-aws.sh
{
    "GroupId": "sg-54bb5b39"
}
Running pre-create checks...
Creating machine...
(mha-consul) Launching instance...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with ubuntu(upstart)...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env mha-consul
Unable to find image 'progrium/consul:latest' locally
latest: Pulling from progrium/consul
…
ba8851f89e33: Pull complete
5d1cefca2a28: Pull complete
Digest: sha256:8cc8023462905929df9a79ff67ee435a36848ce7a10f18d6d0faba9306b97274
Status: Downloaded newer image for progrium/consul:latest
747e8da0d1c0563ac08a2d78cb06ed29adbbdadd9483032029296583e7b8de3e
Running pre-create checks...
Creating machine...
(mha-demo0) Launching instance...
.
.
[output removed]
RUNNING HANDLER [ClusterHQ.flocker : restart flocker-control] ******************
changed: [54.173.143.36]

RUNNING HANDLER [ClusterHQ.flocker : restart flocker-dataset-agent] ************
changed: [54.89.100.226]
changed: [52.91.239.197]
changed: [54.173.143.36]

RUNNING HANDLER [ClusterHQ.flocker : restart flocker-container-agent] **********
changed: [52.91.239.197]
changed: [54.89.100.226]
changed: [54.173.143.36]

PLAY RECAP *********************************************************************
52.91.239.197              : ok=27   changed=14   unreachable=0    failed=0
54.173.143.36              : ok=49   changed=33   unreachable=0    failed=0
54.89.100.226              : ok=27   changed=14   unreachable=0    failed=0
```

### After it completes 

```
List your Docker + Flocker machines.

$:-> docker-machine ls
NAME         ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER    ERRORS
mha-consul   -        amazonec2    Running   tcp://54.174.155.130:2376           v1.10.3
mha-demo0    -        amazonec2    Running   tcp://54.86.142.130:2376            v1.10.3
mha-demo1    -        amazonec2    Running   tcp://52.91.14.21:2376              v1.10.3
mha-demo2    -        amazonec2    Running   tcp://54.209.77.52:2376             v1.10.3
```

Create a network
```
$:-> docker network create -d overlay --subnet=10.0.0.0/24 overlay1
ecf3c1b528667bc31d6462f7fbbeda8d500926a423118646fa2ba954311ebdd1
(ecs-flocker-testing)$:->
(ecs-flocker-testing)$:-> docker network ls
NETWORK ID          NAME                DRIVER
ecf3c1b52866        overlay1            overlay
```

It should be available on all nodes now
```
$:-> docker-machine env mha-demo1
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://52.91.14.21:2376"
export DOCKER_CERT_PATH="/Users/wallnerryan/.docker/machine/machines/mha-demo1"
export DOCKER_MACHINE_NAME="mha-demo1"
# Run this command to configure your shell:
# eval $(docker-machine env mha-demo1)
(ecs-flocker-testing)$:-> eval $(docker-machine env mha-demo1)
(ecs-flocker-testing)$:-> docker network ls
NETWORK ID          NAME                DRIVER
9dba9f49d66b        bridge              bridge
cb6d1413c425        none                null
ef18331790c9        host                host
ecf3c1b52866        overlay1            overlay
```

Use Flocker
```
$ export CONTROL_NODE=<control-node-ip-from-agent-yml> to use flockerctl.
$ cp certs/plugin.crt  certs/api_user.crt
$ cp certs/plugin.crt  certs/api_user.crt
$:-> flockerctl --user api_user \
  --control-service $CONTROL_NODE \
  --certs-path=${PWD}/certs \
  list-nodes

SERVER     ADDRESS
5af2b20f   172.20.0.80
ce9c0ec5   172.20.0.108
4b215a26   172.20.0.17
```


