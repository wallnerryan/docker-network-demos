
# HOW TO

### What you need installed.

Make sure `docker-machine` and `aws` cli are installed
```
$:-> docker-machine --version
docker-machine version 0.6.0, build e27fb87

(virtualenv-aws)$:-> aws --version
aws-cli/1.9.1 Python/2.7.10 Darwin/15.2.0 botocore/1.3.1
```

Also, makre sure you have `ansible` and `flocker-ca`
```
pip install ansible
pip install https://clusterhq-archive.s3.amazonaws.com/python/Flocker-1.11.0-py2-none-any.whl
ansible-galaxy install ClusterHQ.flocker -p ./roles
```

### Export environment variables. 

> Note you must use a pre-existing Amazon VPC Network for this to work. Cluster size will aslo be N + 1 as discovery service VM is not counted.

```
# Replace these if you want to use other REGIONS, Images etc.

export MY_AWS_AMI="ami-fce3c696"
export MY_AWS_DEFAULT_REGION="us-east-1"
export MY_AWS_VPC_ID="vpc-5d1c3539"
export MY_AWS_INSTANCE_TYPE="m3.large"
export MY_AWS_SSH_USER="ubuntu"
export MY_SEC_GROUP_NAME="test-sec-group"
export MY_AWS_ZONE="c"
export MY_CLUSTER_SIZE=3
export AWS_SSH_KEYPATH="/Users/<USERNAME>/.ssh/id_rsa"
```

### Set Credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

### Run the installation

> Note, this example for a 4 or 5 node cluster takes about ~15 mins to install.

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
changed: [54.86.142.130]

RUNNING HANDLER [ClusterHQ.flocker : restart flocker-dataset-agent] ************
changed: [54.86.142.130]
changed: [52.91.14.21]
changed: [54.209.77.52]

RUNNING HANDLER [ClusterHQ.flocker : restart flocker-container-agent] **********
changed: [54.86.142.130]
changed: [52.91.14.21]
changed: [54.209.77.52]

PLAY RECAP *********************************************************************
54.86.142.130             : ok=27   changed=14   unreachable=0    failed=0
52.91.14.21               : ok=49   changed=33   unreachable=0    failed=0
54.209.77.52              : ok=27   changed=14   unreachable=0    failed=0
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

Run the Flocker Docker Plugin on each "demo" node runing our Flocker agents.

> Since we used a Ubuntu 14.04 image, we us `service` instead of `systemctl`, also, we're working on automating this. [see here](https://github.com/ClusterHQ/ansible-role-flocker/issues/2)

```
$ scp certs/plugin.* ubuntu@54.86.142.130:/home/ubuntu/
plugin.crt                                                                                                                        100% 1862     1.8KB/s   00:00
plugin.key                                                                                                                        100% 3268     3.2KB/s   00:00
$ scp certs/plugin.* ubuntu@52.91.14.21:/home/ubuntu/
plugin.crt                                                                                                                        100% 1862     1.8KB/s   00:00
plugin.key                                                                                                                        100% 3268     3.2KB/s   00:00
$ scp certs/plugin.* ubuntu@54.209.77.52:/home/ubuntu/
plugin.crt                                                                                                                        100% 1862     1.8KB/s   00:00
plugin.key                                                                                                                        100% 3268     3.2KB/s   00:00

$ ssh ubuntu@54.86.142.130 sudo mv /home/ubuntu/plugin* /etc/flocker
$ ssh ubuntu@52.91.14.21 sudo mv /home/ubuntu/plugin* /etc/flocker
$ ssh ubuntu@54.209.77.52 sudo mv /home/ubuntu/plugin* /etc/flocker

$ ssh ubuntu@54.86.142.130 sudo service flocker-docker-plugin start
$ ssh ubuntu@52.91.14.21 sudo service flocker-docker-plugin start
$ ssh ubuntu@54.209.77.52 sudo service flocker-docker-plugin start
```

Configure your machine to use the `consul` machine as it also runs our Swarm Manager

> Note, Swarm manager is running on 3376 not 2376.

```
$ eval $(docker-machine env mha-consul)
$ export DOCKER_HOST=tcp://54.174.155.130:3376
$ docker -H tcp://54.174.155.130:3376 info
Containers: 4
 Running: 4
 Paused: 0
 Stopped: 0
Images: 3
Server Version: swarm/1.1.3
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 3
.
.
.
```

Create a network
```
$:-> docker network create -d overlay --subnet=10.0.0.0/24 overlay1
ecf3c1b528667bc31d6462f7fbbeda8d500926a423118646fa2ba954311ebdd1
(ecs-flocker-testing)$:->
(ecs-flocker-testing)$:-> docker network ls
NETWORK ID          NAME                DRIVER
$:-> docker network ls
NETWORK ID          NAME                DRIVER
2e2525945cec        mha-demo0/bridge    bridge
509b60f6c99c        mha-demo1/bridge    bridge
b09794fbcfeb        mha-demo2/host      host
8e8e2114527d        mha-demo1/host      host
a625425b9616        mha-demo2/bridge    bridge
d3828be325f0        mha-demo2/none      null
38497997fa97        mha-demo0/none      null
ff031f6c7562        overlay1            overlay
680a7f3c1f98        mha-demo0/host      host
6c2db34b059b        mha-demo1/none      null
```

Using Flocker

#### Using Docker

Simply just use the plugin.
```
$ docker volume create -d flocker --name test1 -o size=10G
test1

$ docker volume ls
DRIVER              VOLUME NAME
local               mha-demo0/b7222dbc0a0c4e0c159572888ada120c01a076442328507719c62b394a4f4876
local               mha-demo0/87384887d0cc500825d0580775f2851cc21ffa6a05cffc5a5025ab1c7bf2a34a
local               mha-demo1/7c20b1f15156c11b8bc3b53f40246d151b107886fa949b14ffc9b3ddac9ee514
local               mha-demo2/dd705178a035707cb42527a72c3bbe7275c71419e6cd1c6da833106e3c639144
flocker             test1
```

Use the volume

```
$docker run -it --volume-driver flocker --name test-container -v test1:/data --net overlay1 -d busybox
eff88b07d5534c652668a19161d291188cc434a05850292f7a4911c6f004c765

$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
eff88b07d553        busybox             "sh"                56 seconds ago      Up 33 seconds                           mha-demo1/test-container

$ docker inspect -f "{{.Mounts}}" test-container
[{test1 /flocker/1a4bba5c-01c5-4512-981a-e22e6fd1e329 /data flocker  true rprivate}]


$ docker network inspect overlay1
[
    {
        "Name": "overlay1",
        "Id": "ff031f6c75621913da7dd37536ec44df624fdc3c1bbbd697f50e873fe4a32b34",
        "Scope": "global",
        "Driver": "overlay",
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.0.0/24"
                }
            ]
        },
        "Containers": {
            "f006d187e8802f4a0544ceb46750d87ce19a60099f02541d2709e4698c784e50": {
                "Name": "test-container",
                "EndpointID": "770389cd4ec2cb3bee219da00bc1bf56c61ebce01465451f58a6b745d26256f7",
                "MacAddress": "02:42:0a:00:00:02",
                "IPv4Address": "10.0.0.2/24",
                "IPv6Address": ""
            }
        },
        "Options": {}
    }
]
```

#### Use FlockerCTL

First, point at your local Docker Toolbox Machine
```
$ eval $(docker-machine env <your-boot2docker-machine>)
```

Install `flokerctl` if you do not have it.
```
$ curl -sSL https://get.flocker.io |sh
```

Use FlockerCTL to list the nodes

> Note, this will show the nodes private addresses.

```
$ export CONTROL_NODE=<control-node-ip-from-agent-yml> to use flockerctl.
$ flockerctl --user plugin \
  --control-service $CONTROL_NODE \
  --certs-path=${PWD}/certs \
  list-nodes

SERVER     ADDRESS
5af2b20f   172.20.0.80
ce9c0ec5   172.20.0.108
4b215a26   172.20.0.17
```

If you created the volume with the above Docker CLI using Flocker plugin, you can view the volume `test1` we created.
```
$ flockerctl --user plugin   --control-service=$CONTROL_NODE   --certs-path ${PWD}/certs   list
DATASET                                SIZE     METADATA                              STATUS         SERVER
1a4bba5c-01c5-4512-981a-e22e6fd1e329   10.00G   maximum_size=10737418240,name=test1   attached ✅   5d733cac (172.20.0.108)
```

### Cleanup

1) Delete any volumes from Flocker
```
$ eval $(docker-machine env mha-consul)
$ export DOCKER_HOST=tcp://<mha-consul-public-ip>:3376
$ docker volume rm test1

$ eval $(docker-machine env <your-boot2docker-machine>)
$ flockerctl --user plugin \
  --control-service $CONTROL_NODE \
  --certs-path=${PWD}/certs \
  destroy -d 1a4bba5c-01c5-4512-981a-e22e6fd1e329
```

2) Delete Instances

Remove from docker-machine (will also remove VMs)
```
$ docker-machine rm mha-consul mha-demo0 mha-demo1 mha-demo2
About to remove mha-consul, mha-demo0, mha-demo1, mha-demo2
Are you sure? (y/n): y
```

3) Remove security group via `aws` or via AWS Console

