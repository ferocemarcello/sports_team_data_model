#!/bin/bash

# Define directories
TERRAFORM_DIR="./terraform"

echo "--- Setting up PostgreSQL with Docker Compose and Terraform ---"

# 1. Stop and remove existing Docker Compose services and volumes for a clean start
echo "Stopping and removing existing Docker Compose services and volumes (if any)..."
# Forcefully remove any lingering container with the specific name
docker rm -f spond-postgres 2>/dev/null || true # <--- ADD THIS LINE
docker-compose down -v

# 2. Start the PostgreSQL database service immediately
echo "Starting PostgreSQL database service..."
docker-compose up -d --build db
if [ $? -ne 0 ]; then
  echo "Failed to start database service."
  exit 1
fi

echo "Waiting for PostgreSQL database to be healthy..."
docker-compose wait db
if [ $? -ne 0 ]; then
  echo "PostgreSQL database did not become healthy."
  exit 1
fi
echo "PostgreSQL database is up and healthy."

# 3. Explicitly drop the database if it exists, to ensure a clean slate for Terraform
# This helps if docker-compose down -v sometimes fails to remove the volume content or if a previous run left data.
echo "Ensuring clean database state: Dropping 'spond_analytics' if it exists..."
docker exec -i spond-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS spond_analytics;"
if [ $? -ne 0 ]; then
  echo "Failed to drop database 'spond_analytics'."
  exit 1
fi
echo "Database 'spond_analytics' dropped (if it existed)."


# 4. Initialize Terraform and apply configuration to create ONLY the database
echo "Initializing Terraform..."
rm -f "$TERRAFORM_DIR"/terraform.tfstate*
cd "$TERRAFORM_DIR" || { echo "Error: Missing terraform directory."; exit 1; }
terraform init
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed."
  exit 1
fi
echo "Applying Terraform configuration to create database..."
terraform apply -auto-approve -target=postgresql_database.spond_analytics
if [ $? -ne 0 ]; then
  echo "Terraform apply failed."
  exit 1
fi
cd - > /dev/null

# 5. Now, start the ingester service (it depends on db, which is already running)
echo "Starting Data Ingestion service..."
docker-compose up -d --build ingester

# 6. Wait for the ingester container to complete its job
echo "Waiting for data ingestion to complete..."
INGESTER_CONTAINER_ID=$(docker-compose ps -q ingester)
if [ -z "$INGESTER_CONTAINER_ID" ]; then
  echo "Ingester container not found. Check docker-compose.yml and logs."
  exit 1
fi

docker wait "$INGESTER_CONTAINER_ID" > /dev/null
INGESTER_EXIT_CODE=$?

if [ "$INGESTER_EXIT_CODE" -eq 0 ]; then
  echo "Data ingestion process completed successfully."
else
  echo "Data ingestion process completed with errors (exit code: $INGESTER_EXIT_CODE)."
fi

# 7. Show logs for verification (optional)
echo "--- Ingestion Logs ---"
docker-compose logs ingester

echo "--- Verification ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: SELECT COUNT(*) FROM teams;"