
#!/bin/bash

export __NODE_IP__=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
