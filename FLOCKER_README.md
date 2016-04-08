

# HOW TO

Install Docker Machine

```
export MY_AWS_AMI="ami-fce3c696"
export MY_AWS_DEFAULT_REGION=“us-east-1”
export MY_AWS_VPC_ID="vpc-5d1c3539"
export MY_AWS_INSTANCE_TYPE="m3.large"
export MY_AWS_SSH_USER=“ubuntu”
export MY_SEC_GROUP_NAME=“test-sec-group”
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
