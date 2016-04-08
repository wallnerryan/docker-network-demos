import json
import sys

def main(input_data):
    print input_data[0][u'Name']

if __name__ == '__main__':
    if sys.stdin.isatty():
        raise SystemExit("Must pipe input into this script.")
    stdin_json = json.load(sys.stdin)
    main(stdin_json)
