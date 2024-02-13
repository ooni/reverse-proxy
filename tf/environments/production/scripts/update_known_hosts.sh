#!/bin/bash
set -euxo pipefail
# This script updates the known_hosts file with the SSH host keys of all hosts
# in the ansible inventory. It should be run after the hosts have been added to
# the inventory as part of terraform provisioning process.

# To run you can ovverride the INVENTORY_FILE and KNOWN_HOSTS_FILE variables
# with a specific path
# You can also force the update by settting it to true:
# export FORCE_UPDATE=true ./update_known_hosts.sh
INVENTORY_FILE="${INVENTORY_FILE:-ansible/inventory.ini}"
KNOWN_HOSTS_FILE="${KNOWN_HOSTS_FILE:-ansible/known_hosts}"
FORCE_UPDATE="${FORCE_UPDATE:-false}"

# fetch SSH host keys and update known_hosts
update_known_hosts() {
    local host=$1
    if [ "$FORCE_UPDATE" = true ]; then
        echo "Forcing update of known_hosts for $host"
    # Check if the host already exists in known_hosts
    elif grep -q -F "$host" "$KNOWN_HOSTS_FILE"; then
        echo "$host already exists in known_hosts at `$KNOWN_HOSTS_FILE`"
        return
    fi
    # store new keys
    ssh-keyscan $host >> "$KNOWN_HOSTS_FILE"
}

# Main loop to iterate over hosts in the inventory
while read -r line; do
    # ignore comments and empty lines
    if [[ $line =~ ^[a-zA-Z0-9] ]]; then
        update_known_hosts $line
    fi
# only look at the [all] group
done < <(awk '/^\[/{p=0}/\[all\]/{p=1}p' $INVENTORY_FILE | grep -v '\[' | awk '{print $1}')

