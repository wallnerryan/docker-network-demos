import os
import json
import sys


_AGENT_YML = """
version: 1
control-service:
  hostname: %s
  port: 4524
dataset:
  backend: aws
  access_key_id: %s
  secret_access_key: %s
  region: %s
  zone: %s
"""


def main(input_data):
    instances = [
        {
            u'ip': i[u'Instances'][0][u'PublicIpAddress'],
            u'name': i[u'Instances'][0][u'KeyName']
        }
        for i in input_data[u'Reservations']
    ]

    with open('./ansible_inventory', 'w') as inventory_output:
        inventory_output.write('[flocker_control_service]\n')
        inventory_output.write(instances[0][u'ip'] + '\n')
        inventory_output.write('\n')
        inventory_output.write('[flocker_agents]\n')
        for instance in instances:
            inventory_output.write(instance[u'ip'] + '\n')
        inventory_output.write('\n')
        inventory_output.write('[nodes:children]\n')
        inventory_output.write('flocker_control_service\n')
        inventory_output.write('flocker_agents\n')

    with open('./agent.yml', 'w') as agent_yml:
        agent_yml.write(_AGENT_YML % (instances[0][u'ip'], os.environ['AWS_ACCESS_KEY_ID'], os.environ['AWS_SECRET_ACCESS_KEY'], os.environ['MY_AWS_DEFAULT_REGION'], os.environ['MY_AWS_DEFAULT_REGION'] + os.environ['MY_AWS_ZONE']))


if __name__ == '__main__':
    if sys.stdin.isatty():
        raise SystemExit("Must pipe input into this script.")
    stdin_json = json.load(sys.stdin)
    main(stdin_json)
