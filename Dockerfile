# ===== BUILD STAGE =====
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
ENV GENERATE_SOURCEMAP=false

RUN npm run build

# ===== RUNTIME STAGE =====
FROM nginx:1.29-alpine-slim

RUN rm /etc/nginx/conf.d/default.conf

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /usr/share/nginx/html

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d /etc/nginx/conf.d

COPY --from=builder /app/dist/public /usr/share/nginx/html

USER nginx

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD sh -c '\
    FILE=$(find /usr/share/nginx/html/assets -type f -name "*.js" | head -n 1); \
    [ -f "$FILE" ] || exit 1; \
    NAME=$(basename "$FILE"); \
    DISK_SHA=$(sha256sum "$FILE" | cut -d" " -f1); \
    LIVE_SHA=$(wget -qO- http://127.0.0.1/assets/$NAME | sha256sum | cut -d" " -f1); \
    [ -n "$LIVE_SHA" ] || exit 1; \
    [ "$DISK_SHA" = "$LIVE_SHA" ] || exit 1; \
    exit 0; \
  '
EXPOSE 80