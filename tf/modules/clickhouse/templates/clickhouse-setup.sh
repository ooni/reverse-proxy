#!/bin/bash
sudo hostnamectl set-hostname --static ${hostname}

# This only needs to be run the first time to initialize the volume
# sudo mkfs.ext4 -q -F ${device_name}
sudo mkdir -p /var/lib/clickhouse
sudo mount ${device_name} /var/lib/clickhouse
echo "${device_name} /var/lib/clickhouse ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo chown -R clickhouse:clickhouse /var/lib/clickhouse
