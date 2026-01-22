# Stage 1: Build the Ignite website on macOS-compatible Swift
FROM swift:6.2-jammy AS builder

WORKDIR /build

# Copy SharedModels package
COPY SharedModels ./SharedModels

# Copy CfPWebsite package
COPY CfPWebsite ./CfPWebsite

WORKDIR /build/CfPWebsite

# Build and run the site generator
RUN swift build -c release
RUN swift run

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy the generated static site
COPY --from=builder /build/CfPWebsite/Build /usr/share/nginx/html

# Custom nginx config for SPA routing
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    error_page 404 /404.html; \
    location = /404.html { \
        internal; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
