#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Setup PostgreSQL using Docker and Terraform ---
echo "--- Setting up PostgreSQL with Docker and Terraform ---"

# Start a local PostgreSQL Docker container
# Using a specific host port (e.g., 5432) for consistency
echo "Starting PostgreSQL Docker container..."
docker run --name spond-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16-alpine

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
until docker exec spond-postgres pg_isready -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 5
done
echo "PostgreSQL is up and running!"

# Initialize Terraform (if not already initialized)
echo "Initializing Terraform..."
cd terraform
terraform init

# Apply Terraform configuration to create database and tables
echo "Applying Terraform configuration..."
terraform apply -auto-approve
cd .. # Go back to the root directory

echo "PostgreSQL database and tables created successfully."


# --- 2. Build and Run Data Ingestion Docker Container ---
echo "--- Building and Running Data Ingestion Container ---"

# Create a 'data' directory if it doesn't exist and put your CSVs there
mkdir -p data
# Assume your CSV files (teams.csv, members.csv, events.csv, event_rsvps.csv) are in this 'data' directory

echo "Building Docker image for data ingestion..."
docker build -t spond-data-ingester .

echo "Running data ingestion..."
# Run the ingestion container, linking to the PostgreSQL container
# Pass DB connection details as environment variables
docker run --rm \
    --network host \
    -e DB_HOST="localhost" \
    -e DB_PORT="5432" \
    -e DB_NAME="spond_analytics" \
    -e DB_USER="postgres" \
    -e DB_PASSWORD="postgres" \
    -v "$(pwd)/data:/app/data" \
    spond-data-ingester

echo "Data ingestion process completed."

# --- 3. Verification (Optional) ---
echo "--- Verifying Data Ingestion (Optional) ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: SELECT COUNT(*) FROM teams;"

# --- Cleanup (Optional) ---
# To stop and remove the PostgreSQL container after verification:
# echo "To stop and remove the PostgreSQL container, run: docker stop spond-postgres && docker rm spond-postgres"
