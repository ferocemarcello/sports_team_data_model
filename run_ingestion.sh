#!/bin/bash

# Define directories
TERRAFORM_DIR="./terraform"

echo "--- Setting up PostgreSQL with Docker Compose and Terraform ---"

# 1. Stop and remove existing Docker Compose services and volumes for a clean start
echo "Stopping and removing existing Docker Compose services and volumes (if any)..."
docker rm -f spond-postgres 2>/dev/null || true # Ensure container is gone
docker-compose down -v

# 2. Start ONLY the PostgreSQL database service in detached mode
echo "Starting PostgreSQL database service..."
docker-compose up -d --build --remove-orphans db
if [ $? -ne 0 ]; then
  echo "Failed to start database service."
  exit 1
fi

echo "Waiting for PostgreSQL database to be healthy..."
MAX_RETRIES=20
RETRY_INTERVAL=3
for i in $(seq 1 $MAX_RETRIES); do
  if docker exec spond-postgres pg_isready -U postgres -d postgres; then
    echo "PostgreSQL database is up and healthy."
    break
  else
    echo "PostgreSQL is not ready yet. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
  fi
  if [ $i -eq $MAX_RETRIES ]; then
    echo "PostgreSQL database did not become healthy within the timeout."
    exit 1
  fi
done

# 3. Explicitly drop the application database if it exists, to ensure a clean slate for Terraform
echo "Ensuring clean database state: Dropping 'spond_analytics' if it exists..."
docker exec -i spond-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS spond_analytics WITH (FORCE);"
if [ $? -ne 0 ]; then
  echo "Failed to drop database 'spond_analytics'."
  exit 1
fi
echo "Database 'spond_analytics' dropped (if it existed)."


# 4. Initialize Terraform and apply configuration to create the application database using the container
echo "Initializing Terraform..."
rm -f "$TERRAFORM_DIR"/terraform.tfstate* # Clean up existing state on host
# Use the absolute path to terraform, which is now /usr/local/bin/terraform
docker-compose run --rm terraform-cli /usr/local/bin/terraform init # <--- UPDATED PATH
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed."
  exit 1
fi
echo "Applying Terraform configuration to create database..."
# Use the absolute path to terraform
docker-compose run --rm terraform-cli /usr/local/bin/terraform apply -auto-approve -target=postgresql_database.spond_analytics # <--- UPDATED PATH
if [ $? -ne 0 ]; then
  echo "Terraform apply failed."
  exit 1
fi

echo "--- Proceeding with dbt actions ---"

# 5. Clean dbt artifacts (important before subsequent dbt commands)
echo "Cleaning dbt artifacts..."
docker-compose run --rm dbt-cli dbt clean --project-dir /usr/app/dbt
if [ $? -ne 0 ]; then
  echo "dbt clean failed."
  exit 1
fi
echo "dbt clean completed successfully."

# 6. Run dbt seed to load all CSV files as tables
echo "Running dbt seed to load all static data (CSVs)..."
docker-compose run --rm dbt-cli dbt seed --project-dir /usr/app/dbt
if [ $? -ne 0 ]; then
  echo "dbt seed failed."
  exit 1
fi
echo "dbt seed completed successfully, CSVs loaded as tables."

# 7. Run dbt build to create all models (staging, marts) and run tests
echo "Running dbt build to create all models and run tests..."
docker-compose run --rm dbt-cli dbt build --target dev
if [ $? -ne 0 ]; then
  echo "dbt build failed."
  exit 1
fi
echo "dbt build completed successfully, all models built and tested."

echo "--- Pipeline Execution Complete ---"

echo "--- Verification ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: "
echo "SELECT COUNT(*) FROM public.stg_teams;"
echo "SELECT COUNT(*) FROM public.stg_memberships;"
echo "SELECT COUNT(*) FROM public.stg_events;"
echo "SELECT COUNT(*) FROM public.stg_event_rsvps;"

# Optional: Keep services running for inspection, or add docker-compose down here to clean up
# docker-compose down