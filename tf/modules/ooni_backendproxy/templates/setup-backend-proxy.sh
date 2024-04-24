#!/bin/bash
set -e

sudo apt update
sudo apt install -y nginx

tmpfile=$(mktemp /tmp/nginx-config.XXXXXX)
cat > $tmpfile <<EOF
server {
    listen 80;

    server_name _;

    location / {
        proxy_pass ${backend_url};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
EOF
sudo mv $tmpfile /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl reload nginx
