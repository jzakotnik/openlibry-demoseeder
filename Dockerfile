# OpenLibry Demo Data Seeder
# Lightweight Alpine-based container that seeds demo data via REST APIs

FROM alpine:3.19

LABEL org.opencontainers.image.title="OpenLibry Demo Seeder"
LABEL org.opencontainers.image.description="Seeds OpenLibry with demo users, books, and rentals"
LABEL org.opencontainers.image.source="https://github.com/jzakotnik/openlibry"

# Install curl for API calls
RUN apk add --no-cache \
    curl \
    bash

# Create app directory
WORKDIR /app

# Copy seed script
COPY seed.sh /app/seed.sh
RUN chmod +x /app/seed.sh

# Configuration via environment variables
ENV OPENLIBRY_URL=http://localhost:3000
ENV WAIT_TIMEOUT=60
ENV SKIP_COVERS=false

# Run the seed script
ENTRYPOINT ["/app/seed.sh"]
