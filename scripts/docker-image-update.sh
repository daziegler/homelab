#!/bin/bash
set -e

# This script must be placed in the same directory as your docker-compose.yml

# Navigate to the directory of this script (so it works from anywhere)
cd "$(dirname "$0")"

echo "Pulling latest images..."
docker compose pull

echo "Recreating containers with updated images..."
docker compose up -d

echo "Cleaning up old images..."
docker image prune -f

echo "✅ Update complete!"
