#!/bin/bash
set -e

sudo apt update
sudo apt install -y nginx

tmpfile=$(mktemp /tmp/nginx-config.XXXXXX)
cat > $tmpfile <<EOF
stream {
    upstream clickhouse_backend {
        server ${clickhouse_url}:${clickhouse_port};
    }

    server {
        listen 9000;

       proxy_pass clickhouse_backend; 
    } 
}
EOF
sudo mv $tmpfile /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl reload nginx
