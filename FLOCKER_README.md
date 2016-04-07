

# HOW TO

Install Docker Machine

```
export MY_AWS_AMI="ami-971a65e0"
export MY_AWS_DEFAULT_REGION="eu-west-1"
export MY_AWS_VPC_ID="vpc-69c9a10c"
export MY_AWS_INSTANCE_TYPE="t1.micro"
export MY_AWS_SSH_USER="admin"
```

#### BEFORE YOU USE THE SCRIPT ####

```
pip install ansible
pip install https://clusterhq-archive.s3.amazonaws.com/python/Flocker-1.11.0-py2-none-any.whl
ansible-galaxy install marvinpinto.docker -p ./roles
ansible-galaxy install ClusterHQ.flocker -p ./roles
```

### Run the installation

```
./multihost-flocker-aws.sh
```

### After it completes 

```
export CONTROL_NODE=<control-node-ip-from-agent-yml> to use flockerctl.
```
