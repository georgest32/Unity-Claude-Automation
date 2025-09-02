# Multi-stage build for Documentation Server
# Stage 1: Build documentation
FROM python:3.12 AS builder

# Install build dependencies
RUN pip install mkdocs mkdocs-material mkdocstrings[python] mkdocs-autorefs mkdocs-minify-plugin

# Copy documentation source
WORKDIR /build
COPY mkdocs.yml /build/
COPY docs/ /build/docs/
COPY README.md /build/

# Build documentation
RUN mkdocs build --strict --site-dir /build/site

# Stage 2: Serve documentation
FROM nginx:alpine

# Copy built documentation from builder
COPY --from=builder /build/site /usr/share/nginx/html

# Copy custom nginx configuration
COPY docker/docs/nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Run nginx
CMD ["nginx", "-g", "daemon off;"]