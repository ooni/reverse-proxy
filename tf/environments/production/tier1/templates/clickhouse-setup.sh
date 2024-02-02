#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Install datadog agent
DD_API_KEY=${datadog_api_key} DD_SITE="datadoghq.eu" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

# Install clickhouse following the instructions at: https://clickhouse.com/docs/en/install
sudo apt-get install -y apt-transport-https ca-certificates dirmngr
GNUPGHOME=$(mktemp -d)
sudo GNUPGHOME="$GNUPGHOME" gpg --no-default-keyring --keyring /usr/share/keyrings/clickhouse-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8919F6BD2B48D754
sudo rm -rf "$GNUPGHOME"
sudo chmod +r /usr/share/keyrings/clickhouse-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | sudo tee \
/etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo apt install -y clickhouse-server clickhouse-client
sudo systemctl start clickhouse-server
sudo systemctl enable clickhouse-server

# Configure the ebs data volume
sudo service clickhouse-server stop
sudo mkfs.ext4 -q -F /dev/sdf
sudo mkdir -p /var/lib/clickhouse
sudo mount /dev/sdf /var/lib/clickhouse
echo '/dev/sdf /var/lib/clickhouse ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo chown -R clickhouse:clickhouse /var/lib/clickhouse
sudo service clickhouse-server start