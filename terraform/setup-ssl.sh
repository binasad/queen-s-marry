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
server {
    listen 80;
    server_name aztrosyssalonappapi.ddns.net;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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
