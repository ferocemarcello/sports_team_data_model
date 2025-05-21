#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- PostgreSQL Setup ---
DB_CONTAINER_NAME="spond_postgres"
DB_NAME="spond_db"
DB_USER="user"
DB_PASSWORD="password"
DB_PORT="5432" # Host port for PostgreSQL

echo "--- Setting up local PostgreSQL database ---"

# Stop and remove existing PostgreSQL container if it's running
if [ $(docker ps -q -f name=$DB_CONTAINER_NAME) ]; then
    echo "Stopping existing PostgreSQL container..."
    docker stop $DB_CONTAINER_NAME
fi
if [ $(docker ps -aq -f name=$DB_CONTAINER_NAME) ]; then
    echo "Removing existing PostgreSQL container..."
    docker rm $DB_CONTAINER_NAME
fi

# Create a Docker network if it doesn't exist
NETWORK_NAME="spond_network"
if [ -z "$(docker network ls -q -f name=$NETWORK_NAME)" ]; then
    echo "Creating Docker network: $NETWORK_NAME"
    docker network create $NETWORK_NAME
fi

# Run PostgreSQL container
echo "Starting PostgreSQL container..."
docker run --name $DB_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -e POSTGRES_DB=$DB_NAME \
    -e POSTGRES_USER=$DB_USER \
    -e POSTGRES_PASSWORD=$DB_PASSWORD \
    -p $DB_PORT:$DB_PORT \
    -d postgres:13-alpine

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
PG_READY=0
for i in $(seq 1 30); do
    if docker exec $DB_CONTAINER_NAME pg_isready -U $DB_USER -h localhost -p $DB_PORT; then
        PG_READY=1
        break
    fi
    echo "PostgreSQL not ready yet. Retrying in 2 seconds..."
    sleep 2
done

if [ $PG_READY -eq 0 ]; then
    echo "Error: PostgreSQL did not start in time."
    exit 1
fi
echo "PostgreSQL is ready."

# --- Data Ingestion ---
INGESTION_CONTAINER_NAME="spond_data_ingestor"
IMAGE_NAME="spond_data_ingestor_image"

echo "--- Building Docker image for data ingestion ---"
docker build -t $IMAGE_NAME .

echo "--- Running data ingestion container ---"

# Stop and remove existing ingestion container if it's running
if [ $(docker ps -q -f name=$INGESTION_CONTAINER_NAME) ]; then
    echo "Stopping existing ingestion container..."
    docker stop $INGESTION_CONTAINER_NAME
fi
if [ $(docker ps -aq -f name=$INGESTION_CONTAINER_NAME) ]; then
    echo "Removing existing ingestion container..."
    docker rm $INGESTION_CONTAINER_NAME
fi

# Run the data ingestion container
docker run --name $INGESTION_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -e DB_HOST=$DB_CONTAINER_NAME \
    -e DB_PORT=$DB_PORT \
    -e DB_NAME=$DB_NAME \
    -e DB_USER=$DB_USER \
    -e DB_PASSWORD=$DB_PASSWORD \
    $IMAGE_NAME

echo "Data ingestion process initiated. Check container logs for details."
echo "To check if data has been successfully loaded, connect to the PostgreSQL database:"
echo "  docker exec -it $DB_CONTAINER_NAME psql -U $DB_USER -d $DB_NAME"
echo "  Then, you can run commands like: \\dt or SELECT COUNT(*) FROM teams;"

echo "Setup complete!"