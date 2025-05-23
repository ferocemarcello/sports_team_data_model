#!/bin/bash

# Define directories
TERRAFORM_DIR="./terraform"
DBT_DIR="./dbt" # New

echo "--- Setting up PostgreSQL with Docker Compose and Terraform ---"

# 1. Stop and remove existing Docker Compose services and volumes for a clean start
echo "Stopping and removing existing Docker Compose services and volumes (if any)..."
docker rm -f spond-postgres 2>/dev/null || true # Ensure container is gone
docker-compose down -v

# 2. Start the PostgreSQL database service immediately
echo "Starting PostgreSQL database service..."
docker-compose up -d --build db
if [ $? -ne 0 ]; then
  echo "Failed to start database service."
  exit 1
fi

echo "Waiting for PostgreSQL database to be healthy..."
MAX_RETRIES=20 # Increased retries as DB might take longer to be fully ready for pg_isready
RETRY_INTERVAL=3 # seconds
for i in $(seq 1 $MAX_RETRIES); do
  # Use docker exec to run pg_isready inside the container
  # We connect to 'postgres' database initially to allow database creation
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
docker exec -i spond-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS spond_analytics WITH (FORCE);" # FORCE added for robustness
if [ $? -ne 0 ]; then
  echo "Failed to drop database 'spond_analytics'."
  exit 1
fi
echo "Database 'spond_analytics' dropped (if it existed)."


# 4. Initialize Terraform and apply configuration to create the application database
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

# 5. Run the Ingestion service (one-off) to load raw data
echo "Starting Data Ingestion service..."
# --force-recreate ensures a fresh run every time
docker-compose up --build --force-recreate --no-deps ingester
if [ $? -ne 0 ]; then
  echo "Data ingestion service failed to start or run."
  exit 1
fi

echo "Waiting for data ingestion to complete..."
INGESTER_CONTAINER_ID=$(docker-compose ps -q ingester)
if [ -z "$INGESTER_CONTAINER_ID" ]; then
  echo "Ingester container not found after starting. Check docker-compose.yml and logs."
  exit 1
fi

# Wait for the ingester container to exit (as it's a one-off task)
docker wait "$INGESTER_CONTAINER_ID" > /dev/null
INGESTER_EXIT_CODE=$?

if [ "$INGESTER_EXIT_CODE" -eq 0 ]; then
  echo "Data ingestion process completed successfully."
else
  echo "Data ingestion process completed with errors (exit code: $INGESTER_EXIT_CODE)."
  # Optionally, exit here if ingestion failure should stop the whole pipeline
  exit 1
fi

# 6. Run dbt to build models and tests
echo "Running dbt transformations and tests..."
# 'docker-compose run --rm dbt-cli' executes a command in a new ephemeral dbt-cli container
# The 'dbt build' command runs 'dbt run' and 'dbt test'
docker-compose run --rm dbt-cli dbt build --target dev
if [ $? -ne 0 ]; then
  echo "dbt build failed."
  exit 1
fi
echo "dbt transformations and tests completed successfully."

echo "--- Pipeline Execution Complete ---"

# 7. Show logs for verification (optional)
echo "--- Ingestion Logs ---"
docker-compose logs ingester

echo "--- dbt Logs ---"
# You might need to adjust this if dbt run produces logs in a different container after --rm
# Consider docker-compose logs spond-dbt-cli if you want to see the last dbt logs.

echo "--- Verification ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: "
echo "SELECT COUNT(*) FROM raw_teams;"
echo "SELECT COUNT(*) FROM stg_teams;"
echo "SELECT COUNT(*) FROM teams;"
echo "SELECT * FROM events_with_rsvps LIMIT 5;"

# Optional: Keep services running for inspection, or add docker-compose down here to clean up
# docker-compose down # Uncomment to automatically stop all services after script completion