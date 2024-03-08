#!/bin/bash
set -e

sudo apt update
sudo apt install -y nginx

sudo bash -c "cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;

    server_name _;

    location / {
        proxy_pass https://backend-fsn.ooni.org/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
EOF"

sudo nginx -t
sudo systemctl reload nginx
