#!/bin/bash

set -e

echo "--- Setting up PostgreSQL with Docker and Terraform ---"

# Stop and remove any existing PostgreSQL container
echo "Stopping and removing existing PostgreSQL Docker container (if any)..."
docker stop spond-postgres &> /dev/null || true
docker rm spond-postgres &> /dev/null || true

# Clean up Terraform state files for a fresh start
# This ensures Terraform re-creates all resources, including tables, from scratch
echo "Cleaning up Terraform state files..."
rm -f terraform/terraform.tfstate
rm -f terraform/terraform.tfstate.backup

# Start PostgreSQL Docker container
echo "Starting PostgreSQL Docker container..."
docker run --name spond-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16-alpine

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
PG_READY=0
for i in $(seq 1 30); do
  if docker exec spond-postgres pg_isready -h localhost -p 5432 -U postgres; then
    PG_READY=1
    break
  fi
  sleep 2
done

if [ "$PG_READY" -eq 1 ]; then
  echo "PostgreSQL is up and running!"
else
  echo "PostgreSQL did not start in time. Exiting."
  exit 1
fi

# Initialize Terraform (if not already initialized)
echo "Initializing Terraform..."
cd terraform
terraform init

# Apply Terraform configuration to create database and tables
# -auto-approve is used to automatically approve the plan, suitable for scripts
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Go back to the root directory
cd ..

echo "PostgreSQL database and tables created successfully."

echo "--- Building and Running Data Ingestion Container ---"

# Build Docker image for data ingestion
echo "Building Docker image for data ingestion..."
docker build -t spond-data-ingester .

# Run data ingestion
echo "Running data ingestion..."
docker run --network host \
           -e DB_HOST="localhost" \
           -e DB_PORT="5432" \
           -e DB_NAME="spond_analytics" \
           -e DB_USER="postgres" \
           -e DB_PASSWORD="postgres" \
           -v "$(pwd)/data:/app/data" \
           spond-data-ingester python ingest_data.py

echo "Data ingestion complete."
echo "Database connection closed."
echo "Data ingestion process completed."

echo "--- Verifying Data Ingestion (Optional) ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: SELECT COUNT(*) FROM teams;"