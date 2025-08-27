FROM node:20-slim

WORKDIR /app

# Install tools (netcat, python3), plus openssl and curl for HTTPS callback delivery
RUN apt-get update && apt-get install -y \
    netcat-openbsd \
    python3 \
    python3-urllib3 \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories and a self-signed cert for HTTPS callback
RUN mkdir -p /config/tokens /config/ssl \
 && openssl req -x509 -nodes -newkey rsa:2048 -subj "/CN=127.0.0.1" -keyout /config/ssl/key.pem -out /config/ssl/cert.pem -days 3650

COPY package.json ./
COPY src ./src

RUN npm install --production

# Copy default config if it doesn't exist
COPY config/emailproxy.config /config/emailproxy.config

EXPOSE 1993 1587 18089

CMD ["node", "src/index.js"]
