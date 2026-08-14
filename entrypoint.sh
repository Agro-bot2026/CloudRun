#!/bin/bash
# 🦇 CloudRun Proxy Reverso - rutea por header "Backend: svN"
# Uso: PROXY_TARGETS="IP1:puerto,IP2:puerto,..." (el primero es el default)

set -e

# ─── Guard: PROXY_TARGETS obligatorio ───
if [ -z "$PROXY_TARGETS" ]; then
    echo "❌ Falta la variable PROXY_TARGETS"
    echo "   Ejemplo: PROXY_TARGETS='1.2.3.4:80,5.6.7.8:80'"
    echo "   El header 'Backend: sv1' rutea al primer target, 'sv2' al segundo, etc."
    exit 1
fi

PORT="${PORT:-8080}"
echo "🌐 Proxy activo en puerto $PORT"
echo "🎯 Targets: $PROXY_TARGETS"

cat > /etc/nginx/sites-available/proxy_backend <<EOF
server {
    listen $PORT;
    access_log off;

    proxy_connect_timeout 5s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # Resolver DNS en runtime (para targets por nombre de dominio)
    resolver 8.8.8.8 valid=30s;

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

        # HTTP/1.1 + upgrade websocket (necesario para túneles HTTP Custom)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/proxy_backend /etc/nginx/sites-enabled/

nginx -t && nginx -g "daemon off;"
