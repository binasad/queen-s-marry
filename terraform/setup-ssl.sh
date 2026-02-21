#!/bin/bash
# SSL setup for aztrosyssalonappapi.ddns.net on EC2
# Run this script on the EC2 instance: bash setup-ssl.sh
#
# Prerequisites:
# - Backend must be running on port 5000 (Docker or node)
# - Domain aztrosyssalonappapi.ddns.net must resolve to this EC2's Elastic IP

set -e
DOMAIN="aztrosyssalonappapi.ddns.net"

echo "=== Installing Nginx and Certbot ==="
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

echo "=== Creating Nginx config (HTTP only for cert validation) ==="
sudo tee /etc/nginx/sites-available/salon-api << 'NGINX'
# CORS: allow admin-web (Vercel) and localhost
map $http_origin $cors_origin {
    default "";
    "~^https://[a-z0-9-]+\.vercel\.app$" $http_origin;
    "~^https://aztrosyssalonappapi\.ddns\.net$" $http_origin;
    "~^http://localhost(:[0-9]+)?$" $http_origin;
    "~^http://127\.0\.0\.1(:[0-9]+)?$" $http_origin;
}

server {
    listen 80;
    server_name aztrosyssalonappapi.ddns.net;

    location / {
        # Handle CORS preflight in Nginx (ensures response even if backend is slow/down)
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' $cors_origin always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Access-Control-Max-Age' 86400;
            add_header 'Content-Length' 0;
            return 204;
        }

        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Origin $http_origin;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/salon-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "=== Obtaining SSL certificate from Let's Encrypt ==="
# Optional: pass your email for expiry notifications: bash setup-ssl.sh your@email.com
if [ -n "$1" ]; then
  sudo certbot --nginx -d aztrosyssalonappapi.ddns.net --non-interactive --agree-tos -m "$1"
else
  sudo certbot --nginx -d aztrosyssalonappapi.ddns.net --non-interactive --agree-tos --register-unsafely-without-email
fi

echo "=== SSL setup complete! ==="
echo "Your API is now available at: https://aztrosyssalonappapi.ddns.net"
echo "Update your app .env: API_BASE_URL=https://aztrosyssalonappapi.ddns.net/api/v1"
