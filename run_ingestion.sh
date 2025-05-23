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

# 5. Run the Ingestion service (one-off) to load raw data and stream its output
echo "--- Starting Data Ingestion service and capturing its output ---"
# 'docker-compose up' with --abort-on-container-exit will stream logs and exit when the service exits
# We also redirect stderr to stdout (2>&1) to ensure all Python print/error messages are visible.
docker-compose up --build --force-recreate --no-deps --abort-on-container-exit ingester 2>&1
INGESTER_EXIT_CODE=$? # Capture the exit code of the ingester service

if [ "$INGESTER_EXIT_CODE" -eq 0 ]; then
  echo "--- Data ingestion process completed successfully (exit code: 0) ---"
else
  echo "--- Data ingestion process completed with errors (exit code: $INGESTER_EXIT_CODE) ---"
  echo "!!! Stopping script due to ingestion failure. !!!"
  exit 1 # Crucially, exit here if ingestion failed so dbt doesn't run on empty tables
fi

# --- NEW DEBUGGING: Verify data exists from a fresh psql connection before dbt runs ---
echo "--- Verifying ingested data with psql directly from the db container ---"
sleep 1 # Give a very brief moment, though not strictly necessary after ingestion success

# Define the tables to check
TABLES=("teams" "memberships" "events" "event_rsvps")

# Loop through each table and try to count rows
for TABLE in "${TABLES[@]}"; do
  echo "Checking public.$TABLE existence and row count..."
  docker exec -i spond-postgres psql -U postgres -d spond_analytics -c "SELECT COUNT(*) FROM public.$TABLE;"
  if [ $? -ne 0 ]; then
    echo "ERROR: Table public.$TABLE could not be queried by psql. This indicates a deeper database access issue."
    exit 1 # Stop the script if psql can't even see the tables
  else
    echo "SUCCESS: public.$TABLE queried successfully by psql."
  fi
done

echo "--- psql verification complete. Proceeding with dbt build ---"

# --- START: MODIFIED SECTION FOR DBT CLEAN ---
echo "Cleaning dbt artifacts..."
# Removed --project-dir as working_dir is already set correctly
docker-compose run --rm dbt-cli dbt clean
if [ $? -ne 0 ]; then
  echo "dbt clean failed."
  exit 1
fi
# --- END: MODIFIED SECTION FOR DBT CLEAN ---

# 6. Run dbt to build models and tests
echo "Running dbt transformations and tests..."
# Removed --project-dir here too for consistency
docker-compose run --rm dbt-cli dbt build --target dev
if [ $? -ne 0 ]; then
  echo "dbt build failed."
  exit 1
fi
echo "dbt transformations and tests completed successfully."

echo "--- Pipeline Execution Complete ---"

# 7. Show logs for verification (optional)
# No need for separate 'docker-compose logs ingester' anymore as logs are streamed directly in Step 5

echo "--- Verification ---"
echo "You can connect to the database to verify data:"
echo "psql -h localhost -p 5432 -U postgres -d spond_analytics"
echo "Then run queries like: "
echo "SELECT COUNT(*) FROM teams;"
echo "SELECT COUNT(*) FROM memberships;"
echo "SELECT COUNT(*) FROM events;"
echo "SELECT COUNT(*) FROM event_rsvps;"
echo "SELECT * FROM events_with_rsvps LIMIT 5;"

# Optional: Keep services running for inspection, or add docker-compose down here to clean up
# docker-compose down # Uncomment to automatically stop all services after script completion