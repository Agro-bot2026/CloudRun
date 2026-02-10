#!/bin/bash

cat > /etc/nginx/sites-available/proxy_backend <<EOF
server {
    listen 8080;
    access_log off;

    proxy_connect_timeout 5s;
    proxy_send_timeout 10s;
    proxy_read_timeout 10s;

EOF

IFS=',' read -ra TARGETS <<< "$PROXY_TARGETS"

DEFAULT="${TARGETS[0]}"
echo "    set \$backend_url \"http://$DEFAULT\";" >> /etc/nginx/sites-available/proxy_backend

i=1
for entry in "${TARGETS[@]}"; do
    echo "    if (\$http_backend = \"sv$i\") { set \$backend_url \"http://$entry\"; }" >> /etc/nginx/sites-available/proxy_backend
    ((i++))
done

cat >> /etc/nginx/sites-available/proxy_backend <<EOF

    location / {
        proxy_pass \$backend_url;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/proxy_backend /etc/nginx/sites-enabled/

nginx -g "daemon off;"
