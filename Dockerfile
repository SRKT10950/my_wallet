# Stage 1: Build Flutter Web application
FROM ghcr.io/cirrusci/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first to leverage Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application code and build web release
COPY . .
RUN flutter build web --release

# Stage 2: Serve with lightweight Nginx web server
FROM nginx:alpine

# Copy custom Nginx configuration for Flutter PWA routing & caching
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web artifacts from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 3000 8082 80

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/healthz || wget --no-verbose --tries=1 --spider http://127.0.0.1:8082/healthz || wget --no-verbose --tries=1 --spider http://127.0.0.1:80/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
