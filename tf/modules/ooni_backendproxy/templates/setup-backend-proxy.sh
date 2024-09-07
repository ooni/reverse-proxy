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

    error_log /var/log/nginx/error.log;
}
EOF
sudo mv $tmpfile /etc/nginx/sites-available/default


tmpfile_stream=$(mktemp /tmp/nginx-config.XXXXXX)
cat > $tmpfile_stream <<EOF
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
sudo mv $tmpfile_stream /etc/nginx/modules-enabled/stream.config

sudo nginx -t
sudo systemctl reload nginx
