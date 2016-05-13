
export vars

```
export OS_API_KEY=<KEY>
export OS_USERNAME=<USERNAME>
export OS_REGION_NAME=<REGION>
export MY_CLUSTER_SIZE=3 # or another number of cluster nodes.
```

run the script
```
./multihost-flocker-rax.sh
```

Create an agent yml to help install flocker
```
version: 1
control-service:
    hostname: "user.controlserver.example.com"
    port: 4524
dataset:
    backend: "openstack"
    region: "<REGION_USED_ABOVE>"
    auth_plugin: "rackspace"
    username: "<your rackspace username>"
    api_key: "<your rackspace API key>"
    auth_url: "https://identity.api.rackspacecloud.com/v2.0"
```

You can then use our ansible playbook to install flocker

All SSH keys are stored in docker-machine config, so we can add them to the ansible inventory
```
$ cat inventory
[flocker_control_service]
162.242.221.24	ansible_ssh_private_key_file=~/.docker/machine/machines/mha-consul/id_rsa

[flocker_agents]
162.242.246.158 ansible_ssh_private_key_file=~/.docker/machine/machines/mha-demo0/id_rsa
104.130.14.79   ansible_ssh_private_key_file=~/.docker/machine/machines/mha-demo1/id_rsa

[flocker_docker_plugin]
162.242.246.158 ansible_ssh_private_key_file=~/.docker/machine/machines/mha-demo0/id_rsa
104.130.14.79   ansible_ssh_private_key_file=~/.docker/machine/machines/mha-demo1/id_rsa

[nodes:children]
flocker_control_service
flocker_agents
flocker_docker_plugin
```

Set up a simple playbook
```
$ cat playbook.yml
---
- hosts: nodes
  user: root
  roles:
    - role: ClusterHQ.flocker
      flocker_api_cert_name: plugin
      flocker_install_docker_plugin: true
```

Then run the playbook
```
ansible-playbook \
  -i inventory playbook.yml \
  --extra-vars "flocker_agent_yml_path=${pwd}agent.yml"
.
.
.
PLAY RECAP *********************************************************************
104.130.14.79              : ok=33   changed=19   unreachable=0    failed=0
162.242.221.24             : ok=40   changed=26   unreachable=0    failed=0
162.242.246.158            : ok=33   changed=19   unreachable=0    failed=0
```


