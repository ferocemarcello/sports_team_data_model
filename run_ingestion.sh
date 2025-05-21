#!/bin/bash

# --- run_ingestion.sh ---
# This script automates the setup and execution of the Spond data ingestion
# process using Docker Compose. It will:
# 1. Check for Docker Compose installation.
# 2. Build and start the PostgreSQL database and the ingestion application.
# 3. Provide instructions to verify data ingestion.
# 4. Provide instructions to stop the services.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Spond Data Ingestion Setup and Run Script ---"

# 1. Check for Docker Compose installation
if ! command -v docker-compose &> /dev/null
then
    echo "Error: docker-compose is not installed."
    echo "Please install Docker Desktop (which includes Docker Compose) or Docker Engine with Docker Compose plugin."
    echo "Refer to Docker's official documentation for installation instructions."
    exit 1
fi

echo "Docker Compose detected. Proceeding with setup."

# Define the project directory (assuming script is run from the root of the project)
PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

echo "Current working directory: $(pwd)"

# 2. Build and start the PostgreSQL database and the ingestion application
echo ""
echo "--- Starting Docker Compose services (PostgreSQL and Ingestion App) ---"
echo "This may take a few moments as images are built/pulled and services start."
echo "The ingestion app will run and then exit automatically after data is loaded."
echo ""

# Run docker-compose up with --build to ensure the latest image is used
# and --abort-on-container-exit to stop all services if the ingestion_app exits
docker-compose up --build --abort-on-container-exit

echo ""
echo "--- Docker Compose services have finished. ---"
echo "The 'ingestion_app' container should have completed its task and exited."
echo "The 'spond_postgres_db' container should still be running in the background."

# 3. Provide instructions to verify data ingestion
echo ""
echo "--- Data Verification Instructions ---"
echo "To verify that the data has been successfully ingested into PostgreSQL, you can connect to the database:"
echo "1. Open a new terminal window."
echo "2. Run the following command to connect to the PostgreSQL container's psql client:"
echo "   docker exec -it spond_postgres_db psql -U spond_user -d spond_db"
echo ""
echo "Once connected to psql, you can run these SQL queries:"
echo "   \\dt;                 -- List all tables"
echo "   SELECT * FROM teams LIMIT 5;    -- View sample data from teams table"
echo "   SELECT * FROM members LIMIT 5;  -- View sample data from members table"
echo "   SELECT * FROM events LIMIT 5;   -- View sample data from events table"
echo "   SELECT * FROM event_rsvps LIMIT 5; -- View sample data from event_rsvps table"
echo "   \\q                   -- Exit psql"
echo ""

# 4. Provide instructions to stop the services
echo "--- Stopping Services Instructions ---"
echo "When you are done, you can stop and remove the Docker containers and networks by running:"
echo "   docker-compose down"
echo ""
echo "If you also want to remove the database data volume (resetting the database), use:"
echo "   docker-compose down -v"
echo ""

echo "Script finished."