#!/bin/bash
# EC2 user data – runs on FIRST BOOT as root.
# Installs: Node 20, PM2, Nginx, Certbot, Docker (optional).
# Configures Nginx as a reverse-proxy → localhost:5000 with WebSocket + CORS.
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1   # log everything

DOMAIN="aztrosyssalonappapi.ddns.net"
BACKEND_PORT=5000

echo "===== 1/6  System update ====="
apt-get update && apt-get upgrade -y

echo "===== 2/6  Node.js 20 LTS + PM2 ====="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs build-essential git
npm install -g pm2

echo "===== 3/6  Docker (optional – for DB or future containers) ====="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo "===== 4/6  Nginx ====="
apt-get install -y nginx

# Remove the default site so it can never shadow our config
rm -f /etc/nginx/sites-enabled/default

# Write the Nginx reverse-proxy config
cat > /etc/nginx/sites-available/salon-api << 'NGINX'
# Block PHP scanners and common exploit paths
map $uri $is_bad_request {
    default      0;
    ~*\.php$     1;
    ~*eval-stdin 1;
    ~*wp-admin   1;
    ~*wp-login   1;
    ~*/etc/passwd 1;
    ~*union.*select 1;
}

# ---------- WebSocket upgrade map ----------
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name aztrosyssalonappapi.ddns.net;

    client_max_body_size 10m;

    # Drop bad requests silently (no response = wastes attacker's time)
    if ($is_bad_request) { return 444; }

    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Origin            $http_origin;
        proxy_cache_bypass                 $http_upgrade;
        proxy_read_timeout                 86400s;
    }

    location /socket.io/ {
        proxy_pass         http://127.0.0.1:5000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass                 $http_upgrade;
        proxy_read_timeout                 86400s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/salon-api /etc/nginx/sites-enabled/salon-api
nginx -t && systemctl enable nginx && systemctl restart nginx

echo "===== 5/6  App directory & salon-backend startup ====="
mkdir -p /home/ubuntu/salon-backend /home/ubuntu/Aztrosys/backend
chown -R ubuntu:ubuntu /home/ubuntu/salon-backend /home/ubuntu/Aztrosys

# Systemd service to start salon-backend container on boot (after Docker is ready)
# Safe if container doesn't exist yet (before first CI/CD deployment)
cat > /etc/systemd/system/salon-backend-docker.service << 'SVC'
[Unit]
Description=Start salon-backend Docker container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'docker ps -a -q -f name=^salon-backend$ | xargs -r docker start'
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable salon-backend-docker.service

echo "===== 6/6  Certbot (dry-run – run setup-ssl.sh manually after DNS resolves) ====="
apt-get install -y certbot python3-certbot-nginx
echo "Run 'sudo bash setup-ssl.sh [email]' once the domain resolves to this IP."

echo "===== User-data complete! ====="
