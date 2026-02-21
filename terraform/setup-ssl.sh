#!/bin/bash
# SSL setup for aztrosyssalonappapi.ddns.net on EC2
# Run this script on the EC2 instance: sudo bash setup-ssl.sh [email]
#
# Prerequisites:
# - Backend must be running on port 5000 (PM2 or Docker)
# - Domain aztrosyssalonappapi.ddns.net must resolve to this EC2's Elastic IP
# - Nginx must be installed (user-data.sh does this automatically)

set -euo pipefail
DOMAIN="aztrosyssalonappapi.ddns.net"
BACKEND_PORT=5000

echo "=== 1/4  Installing Certbot ==="
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

echo "=== 2/4  Writing Nginx config (HTTP, pre-cert) ==="
sudo tee /etc/nginx/sites-available/salon-api > /dev/null << 'NGINX'
# ---------- CORS origin map ----------
map $http_origin $cors_origin {
    default "";
    "~^https://[a-z0-9-]+\.vercel\.app$"              $http_origin;
    "~^https://aztrosyssalonappapi\.ddns\.net$"        $http_origin;
    "~^http://localhost(:[0-9]+)?$"                    $http_origin;
    "~^http://127\.0\.0\.1(:[0-9]+)?$"                $http_origin;
    "~^http://10\.\d+\.\d+\.\d+(:[0-9]+)?$"          $http_origin;
    "~^http://192\.168\.\d+\.\d+(:[0-9]+)?$"          $http_origin;
}

# ---------- WebSocket upgrade map ----------
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name aztrosyssalonappapi.ddns.net;

    # --- CORS preflight ---
    location / {
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin'      $cors_origin always;
            add_header 'Access-Control-Allow-Methods'     'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
            add_header 'Access-Control-Allow-Headers'     'Content-Type, Authorization, Accept' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Access-Control-Max-Age'           86400;
            add_header 'Content-Length'                    0;
            return 204;
        }

        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # Standard proxy headers
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Origin            $http_origin;

        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
    }

    # --- Socket.IO ---
    location /socket.io/ {
        proxy_pass         http://127.0.0.1:5000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host       $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/salon-api /etc/nginx/sites-enabled/salon-api
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "=== 3/4  Obtaining SSL certificate from Let's Encrypt ==="
if [ -n "${1:-}" ]; then
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$1"
else
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
fi

echo "=== 4/4  Verifying final Nginx config ==="
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "=== SSL setup complete! ==="
echo "API: https://$DOMAIN/api/v1"
echo "WebSocket: wss://$DOMAIN/socket.io/"
echo ""
echo "Certbot auto-renewal is enabled via systemd timer."
echo "Test renewal: sudo certbot renew --dry-run"
