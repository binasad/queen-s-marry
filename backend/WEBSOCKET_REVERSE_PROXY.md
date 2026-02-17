# WebSocket Reverse Proxy Setup

If you see **502 Bad Gateway** when the app connects to Socket.IO, the reverse proxy (nginx, Caddy, Cloudflare, etc.) likely isn't forwarding WebSocket connections.

## nginx

Add to your `server` block:

```nginx
location /socket.io/ {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://localhost:5000;  # Your Node.js backend
    proxy_read_timeout 86400;
}
```

## Caddy

```caddy
reverse_proxy /socket.io/* localhost:5000 {
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-For {remote_host}
}
```

## Cloudflare

1. Go to **SSL/TLS** → **Overview** → set to **Full** or **Full (strict)**
2. **Network** → ensure **WebSockets** is enabled (usually on by default)
3. If using a free plan, some WebSocket features may be limited

## Apache

```apache
<Location /socket.io/>
    ProxyPass http://localhost:5000/socket.io/
    ProxyPassReverse http://localhost:5000/socket.io/
    RewriteEngine on
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) ws://localhost:5000/$1 [P,L]
</Location>
```

## Verify

After configuring, restart the proxy and test:

```bash
# Test WebSocket upgrade (replace with your domain)
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  https://aztrosyssalonappapi.ddns.net/socket.io/?EIO=4&transport=websocket
```

You should see `101 Switching Protocols` instead of 502.
