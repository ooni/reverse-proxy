#!/bin/bash

CLUSTER_ID="{{ cluster_id }}"

create_hsm_token() {
    if [ -z $1 ]; then
       echo "AVAILABILITY ZONE PARAMETER UNSET!"
       exit 1
    fi
    AVAILABILITY_ZONE=$1
    aws cloudhsmv2 create-hsm --cluster-id $CLUSTER_ID --availability-zone $AVAILABILITY_ZONE --hsm-type hsm1.medium
    echo "Creating HSM Token in $AVAILABILITY_ZONE..."
    sleep 5

    while true; do
        STATE=$(aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --query "Clusters[0].Hsms[?State=='ACTIVE'] | length(@)")
        if [ "$STATE" -ge 2 ]; then
            echo "HSM Token $AVAILABILITY_ZONE created and active."
            break
        fi
        echo "Waiting for HSM Token $TOKEN_NAME to become active..."
        sleep 10
    done
}

create_hsm_token eu-central-1a
create_hsm_token eu-central-1b

echo "Extracting IP addresses of created HSM tokens..."
IP_ADDRESSES=$(aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --query "Clusters[0].Hsms[*].EniIp" --output text)
echo "IP Addresses of created HSM tokens: $IP_ADDRESSES"

echo "[+] writing cloudhsm-cli.cfg"
cat <<EOF > /tmp/cloudhsm-cli.cfg
{
    "clusters" : [{
        "type": "hsm1",
        "cluster":{
            "hsm_ca_file": "/opt/cloudhsm/etc/customerCA.crt",
            "servers":[
                {
                    "hostname": "${IP_ADDRESSES[0]}",
                    "port": 2223,
                    "enable": true
                },
                {
                    "hostname": "${IP_ADDRESSES[1]}",
                    "port": 2223,
                    "enable": true
                }
            ]
        }
    }],
    "logging": {
        "log_type": "file",
        "log_file": "/opt/cloudhsm/run/cloudhsm-cli.log",
        "log_level": "info",
        "log_interval": "daily"
    }
}
EOF

sudo mv /tmp/cloudhsm-cli.cfg /opt/cloudhsm/etc/cloudhsm-cli.cfg
sudo chown root:root /opt/cloudhsm/etc/cloudhsm-cli.cfg


echo "[+] writing cloudhsm-pkcs11.cfg"
cat <<EOF > /tmp/cloudhsm-pkcs11.cfg
{
    "clusters" : [{
        "type": "hsm1",
        "cluster":{
            "hsm_ca_file": "/opt/cloudhsm/etc/customerCA.crt",
            "servers":[
                {
                    "hostname": "${IP_ADDRESSES[0]}",
                    "port": 2223,
                    "enable": true
                },
                {
                    "hostname": "${IP_ADDRESSES[1]}",
                    "port": 2223,
                    "enable": true
                }
            ]
        }
    }],
    "logging": {
        "log_type": "file",
        "log_file": "/opt/cloudhsm/run/cloudhsm-pkcs11.log",
        "log_level": "info",
        "log_interval": "daily"
    }
}
EOF
sudo mv /tmp/cloudhsm-pkcs11.cfg /opt/cloudhsm/etc/cloudhsm-pkcs11.cfg
sudo chown root:root /opt/cloudhsm/etc/cloudhsm-pkcs11.cfg