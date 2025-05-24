#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Load Environment Variables ---
# Source the .env file to make variables available to this script directly.
# This is crucial for commands like 'docker exec psql' and the final psql instructions.
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found. Please create it in the same directory as this script."
  exit 1
fi

# --- Configuration Variables ---
TERRAFORM_DIR="./terraform"

echo "--- Starting Spond Data Pipeline Setup ---"

# 1. Stop and remove existing Docker Compose services and volumes for a clean start
echo "1. Ensuring a clean Docker environment (stopping services and wiping all data volumes)..."
# 'docker-compose down -v' stops and removes containers, networks, AND named volumes.
# This ensures a completely fresh database instance every time the script runs.
docker-compose down -v
echo "   Docker Compose environment is now clean."

# 2. Start ONLY the PostgreSQL database service
echo "2. Starting PostgreSQL database service..."
# 'docker-compose up -d' starts services in detached mode.
# '--build' ensures the image is rebuilt if its Dockerfile or context changes.
# '--remove-orphans' removes services not defined in the Compose file (good for iterative development).
# 'db' specifies to only start the 'db' service.
docker-compose up -d --build --remove-orphans db
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start database service."
  exit 1
fi
echo "   PostgreSQL database service started."

# 3. Wait for PostgreSQL database to be healthy
echo "3. Waiting for PostgreSQL database to become healthy..."
MAX_RETRIES=30 # Increased retries for robustness against slow DB startups
RETRY_INTERVAL=2 # Seconds
for i in $(seq 1 $MAX_RETRIES); do
  # Use 'docker exec' to run pg_isready directly inside the 'spond-postgres' container.
  # This checks if the default 'postgres' database is ready to accept connections.
  # We use the default 'postgres' user/db for this initial check.
  if docker exec spond-postgres pg_isready -U postgres -d postgres; then
    echo "   PostgreSQL database is up and healthy."
    break
  else
    echo "   PostgreSQL is not ready yet. Retrying in $RETRY_INTERVAL seconds... (Attempt $i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
  fi
  if [ $i -eq $MAX_RETRIES ]; then
    echo "ERROR: PostgreSQL database did not become healthy within the timeout."
    exit 1
  fi
done

# 4. Explicitly drop the application database if it exists, to ensure a clean slate for Terraform
echo "4. Ensuring clean application database state: Dropping '${POSTGRES_DBNAME}' if it exists..."
# Connect to the default 'postgres' database to drop the application database.
# 'WITH (FORCE)' disconnects any active sessions before dropping, preventing lock issues.
docker exec -i spond-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DBNAME} WITH (FORCE);"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to drop database '${POSTGRES_DBNAME}'."
  exit 1
fi
echo "   Database '${POSTGRES_DBNAME}' dropped (if it existed)."

# 5. Initialize Terraform and apply configuration to create the application database and other resources
echo "5. Initializing and applying Terraform configuration..."
# Remove existing local Terraform state files to ensure a fresh run.
# This is crucial if you are not using remote state management.
rm -f "$TERRAFORM_DIR"/terraform.tfstate*
echo "   Local Terraform state files cleaned."

# Run Terraform init (ensure 'terraform-cli' service is up and its image is built)
docker-compose run --rm terraform-cli /usr/local/bin/terraform init
if [ $? -ne 0 ]; then
  echo "ERROR: Terraform initialization failed."
  exit 1
fi
echo "   Terraform initialized."

# Run Terraform apply to create the database and other specified resources.
# '-auto-approve' skips interactive approval.
# IMPORTANT: The '-target' flag refers to a specific Terraform resource *name* (e.g., 'postgresql_database.spond_analytics')
# as defined in your .tf files. It is NOT the database name from your .env file directly.
# Assuming your Terraform code has a resource block like:
#   resource "postgresql_database" "spond_analytics" { ... }
echo "   Terraform apply to create '${POSTGRES_DBNAME}'..."
docker-compose run --rm terraform-cli /usr/local/bin/terraform apply -auto-approve -target=postgresql_database.spond_analytics
if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed."
  exit 1
fi
echo "   Terraform configuration applied, '${POSTGRES_DBNAME}' database created."

echo "--- Proceeding with dbt data transformations ---"

# 6. Clean dbt artifacts (important before subsequent dbt commands)
echo "6. Cleaning dbt artifacts (target folder, etc.)..."
# 'dbt clean' removes local dbt compilation artifacts for a fresh build.
docker-compose run --rm dbt-cli dbt clean --project-dir /usr/app/dbt
if [ $? -ne 0 ]; then
  echo "ERROR: dbt clean failed."
  exit 1
fi
echo "   dbt artifacts cleaned."

# 7. Run dbt seed to load all CSV files as tables
echo "7. Running dbt seed to load all static data (CSVs) into the database..."
# 'dbt seed' loads data from CSVs into tables based on profiles.yml configuration.
docker-compose run --rm dbt-cli dbt seed --project-dir /usr/app/dbt
if [ $? -ne 0 ]; then
  echo "ERROR: dbt seed failed."
  exit 1
fi
echo "   dbt seed completed successfully, CSVs loaded."

# 8. Run dbt build to create all models (staging, marts) and run tests
echo "8. Running dbt build to create all models and run tests..."
# 'dbt build' runs dbt's compile, run, and test commands sequentially.
docker-compose run --rm dbt-cli dbt build --target dev
if [ $? -ne 0 ]; then
  echo "ERROR: dbt build failed."
  exit 1
fi
echo "   dbt build completed successfully, all models built and tested."

echo "--- Spond Data Pipeline Execution Complete ---"

echo "--- Verification Instructions ---"
echo "You can now connect to the database to verify data (using your .env values):"
# Variables from .env are available because we 'source .env' at the top of the script.
echo "psql -h localhost -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -d ${POSTGRES_DBNAME}"
echo "Then run queries like:"
echo "SELECT COUNT(*) FROM public.stg_teams;"
echo "SELECT COUNT(*) FROM public.stg_memberships;"
echo "SELECT COUNT(*) FROM public.stg_events;"
echo "SELECT COUNT(*) FROM public.stg_event_rsvps;"
echo ""
echo "Note: The Docker Compose services (PostgreSQL, etc.) are still running in the background."
echo "You can shut them down manually at any time with 'docker-compose down'."