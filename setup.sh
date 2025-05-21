#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define Docker image and container names
IMAGE_NAME="spond-data-ingest"
DB_CONTAINER_NAME="spond-postgres-db"
INGESTION_CONTAINER_NAME="spond-ingestion-app"

# Database connection parameters (ensure these match ingest_data.py defaults or your desired values)
DB_HOST="spond-postgres-db" # Hostname for inter-container communication
DB_PORT="5432"
DB_NAME="spond_analytics"
DB_USER="user"
DB_PASSWORD="password"

echo "Building Docker image: $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" .

echo "Starting PostgreSQL container..."
# Run PostgreSQL in a detached mode, expose port 5432, and set environment variables
docker run -d \
  --name "$DB_CONTAINER_NAME" \
  -e POSTGRES_DB="$DB_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -p 5432:5432 \
  postgres:16-alpine # Using a lightweight PostgreSQL image

echo "Waiting for PostgreSQL to be ready..."
# Simple loop to wait for PostgreSQL to be ready. In a real production system, consider a more robust health check.
until docker exec "$DB_CONTAINER_NAME" pg_isready -U "$DB_USER" -h localhost; do
  sleep 2
done
echo "PostgreSQL is ready."

echo "Running data ingestion container..."
# Run the ingestion container, linking it to the PostgreSQL container
docker run --rm \
  --name "$INGESTION_CONTAINER_NAME" \
  --network host \
  -e DB_HOST="localhost" \
  -e DB_PORT="$DB_PORT" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  "$IMAGE_NAME" python ingest_data.py

echo "Data ingestion process completed."
echo "You can connect to the PostgreSQL database at localhost:5432 with user '$DB_USER' and database '$DB_NAME' to verify the data."
echo "To stop and remove the PostgreSQL container, run: docker stop $DB_CONTAINER_NAME && docker rm $DB_CONTAINER_NAME"