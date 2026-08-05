FROM alpine:3.21

LABEL maintainer="baba2580"
LABEL description="Aria-Ariang Lite Server - All-in-One Download & Cloud Sync"
LABEL org.opencontainers.image.source="https://github.com/Akai-Abd/Aria-Ariang-Server-Lite"

# Install all runtime dependencies in a single layer
RUN apk add --no-cache \
    aria2 \
    nginx \
    curl \
    jq \
    bash \
    rclone \
    apache2-utils \
    tzdata

# Create required directories
RUN mkdir -p /config/script /downloads /usr/share/nginx/html /var/www/certbot \
    && rm -f /etc/nginx/http.d/default.conf

# Copy AriaNg static files
COPY ariang/ /usr/share/nginx/html/

# Copy nginx config for all-in-one mode
COPY docker/nginx.conf /etc/nginx/http.d/default.conf

# Copy default aria2 config (entrypoint copies to /config on first run)
COPY aria2/aria2.conf /config/aria2.conf.default
COPY aria2/script.conf /config/script.conf.default

# Copy scripts
COPY script/ /config/script/
RUN chmod +x /config/script/*.sh

# Copy default cloud destinations
COPY cloud-destinations.json /config/cloud-destinations.json.default

# Copy entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Aria2 RPC (6800) is internal only; expose HTTP for users
EXPOSE 80

VOLUME ["/config", "/downloads"]

ENTRYPOINT ["/entrypoint.sh"]
