#!/bin/bash
sudo hostnamectl set-hostname --static ${hostname}

# Install datadog agent
DD_API_KEY=${datadog_api_key} DD_SITE="datadoghq.eu" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

sudo mkfs.ext4 -q -F ${device_name}
sudo mkdir -p /var/lib/clickhouse
sudo mount ${device_name} /var/lib/clickhouse
echo "${device_name} /var/lib/clickhouse ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo chown -R clickhouse:clickhouse /var/lib/clickhouse

