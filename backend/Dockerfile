# ---------- Stage 1: Build ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy app source
COPY . .

# ---------- Stage 2: Production ----------
FROM node:20-alpine

WORKDIR /app

# Copy only needed files from builder
COPY --from=builder /app ./

# Remove dev dependencies
RUN npm prune --production

# App port
EXPOSE 5000

# Start app
CMD ["node", "src/server.js"]
