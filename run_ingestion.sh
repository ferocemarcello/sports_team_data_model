#!/bin/bash

# Define directories
TERRAFORM_DIR="./terraform"

echo "--- Setting up PostgreSQL with Docker Compose and Terraform ---"

# 1. Stop and remove existing Docker Compose services and volumes for a clean start
# This ensures a fresh database each time you run the script, which is good for testing.
echo "Stopping and removing existing Docker Compose services and volumes (if any)..."
docker-compose down -v

# 2. Initialize Terraform and apply configuration to create ONLY the database
# The 'null_resource.create_tables' will be removed from main.tf (see next step)
# as ingest_data.py will handle creating tables.
echo "Initializing Terraform..."
# Remove old terraform state to ensure a fresh apply in development
rm -f "$TERRAFORM_DIR"/terraform.tfstate*
cd "$TERRAFORM_DIR" || { echo "Error: Missing terraform directory."; exit 1; }
terraform init
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed."
  exit 1
fi
echo "Applying Terraform configuration to create database..."
# Target only the database resource. This is more robust if you expand Terraform later.
terraform apply -auto-approve -target=postgresql_database.spond_analytics
if [ $? -ne 0 ]; then
  echo "Terraform apply failed."
  exit 1
fi
cd - > /dev/null # Go back to original directory

# 3. Start Docker Compose services (PostgreSQL and Data Ingestion)
# The --build flag ensures the ingester image is rebuilt if Dockerfile or context changes.
echo "Starting Docker Compose services (PostgreSQL and Data Ingestion)..."
docker-compose up --build -d

# 4. Wait for the ingester container to complete its job
echo "Waiting for data ingestion to complete..."
# Get the container ID of the ingester service
INGESTER_CONTAINER_ID=$(docker-compose ps -q ingester)
if [ -z "$INGESTER_CONTAINER_ID" ]; then
  echo "Ingester container not found or not running. Check docker-compose logs."
  exit 1
fi

# Wait for the container to exit (0 for success, non-zero for error)
docker wait "$INGESTER_CONTAINER_ID" > /dev/null
INGESTER_EXIT_CODE=$?

if [ "$INGESTER_EXIT_CODE" -eq 0 ]; then
  echo "Data ingestion process completed successfully."
else
  echo "Data ingestion process completed with errors (exit code: $INGESTER_EXIT_CODE)."
fi

# 5. Show logs for verification
echo "--- Ingestion Logs ---"
docker-compose logs ingester

echo "--- Verification ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: SELECT COUNT(*) FROM teams;"