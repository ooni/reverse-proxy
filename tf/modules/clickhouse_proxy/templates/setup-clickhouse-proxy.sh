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

    error_log /var/log/nginx/error.log;
}
EOF
sudo mv $tmpfile /etc/nginx/modules-enabled/stream.conf

sudo nginx -t
sudo systemctl reload nginx
