#!/bin/bash
# EC2 user data – runs on FIRST BOOT as root.
# Installs: Node 20, PM2, Nginx, Certbot, Docker (optional).
# Configures Nginx as a reverse-proxy → localhost:5000 with WebSocket + CORS.
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1   # log everything

DOMAIN="aztrosyssalonappapi.ddns.net"
BACKEND_PORT=5000

echo "===== 1/7  System update ====="
apt-get update && apt-get upgrade -y

echo "===== 2/7  Node.js 20 LTS + PM2 ====="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs build-essential git
npm install -g pm2

echo "===== 3/7  Docker (optional – for DB or future containers) ====="
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

echo "===== 4/7  Redis (caching for backend) ====="
apt-get install -y redis-server
sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
systemctl enable redis-server
systemctl start redis-server
echo "Redis listening on 127.0.0.1:6379"

echo "===== 5/7  Nginx ====="
apt-get install -y nginx

# Remove the default site so it can never shadow our config
rm -f /etc/nginx/sites-enabled/default

# Write the Nginx reverse-proxy config
cat > /etc/nginx/sites-available/salon-api << 'NGINX'
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

    # --- CORS preflight (handled by Nginx so it always responds) ---
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
        proxy_read_timeout 86400s;   # keep WS connections alive
    }

    # --- Socket.IO explicit location (belt-and-suspenders) ---
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

ln -sf /etc/nginx/sites-available/salon-api /etc/nginx/sites-enabled/salon-api
nginx -t && systemctl enable nginx && systemctl restart nginx

echo "===== 6/7  App directory & salon-backend startup ====="
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

echo "===== 7/7  Certbot (dry-run – run setup-ssl.sh manually after DNS resolves) ====="
apt-get install -y certbot python3-certbot-nginx
echo "Run 'sudo bash setup-ssl.sh [email]' once the domain resolves to this IP."

echo "===== User-data complete! ====="
