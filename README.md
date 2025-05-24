## Data Description

The project utilizes three sample datasets in CSV format. The schema for these tables is as follows:

| Table         | Column              | Description                                                                 |
|---------------|---------------------|-----------------------------------------------------------------------------|
| `teams`       | `team_id` (string)  | Unique ID                                                                   |
|               | `group_activity` (string) | Activity type of group e.g., football, cricket, rugby, etc.           |
|               | `country_code` (string) | Alpha-3 country code of group e.g., NOR=Norway; GBR=United Kingdom; etc. |
|               | `created_at` (UTC timestamp) | System generated creation timestamp                                       |
| `members`     | `membership_id`     | Unique ID                                                                   |
|               | `team_id`          | Foreign Key                                                                 |
|               | `role_title` (string) | member or admin                                                             |
|               | `joined_at` (UTC timestamp) | System generated creation timestamp                                       |
| `events`      | `event_id`          | Unique ID                                                                   |
|               | `team_id`           | Foreign Key                                                                 |
|               | `event_start` (UTC timestamp) | User-defined event start timestamp                                          |
|               | `event_end` (UTC timestamp)   | User-defined event end timestamp                                            |
|               | `created_at` (UTC timestamp) | System generated creation timestamp                                       |
| `event_rsvps` | `event_rsvp_id`     | Unique ID                                                                   |
|               | `event_id`          | Foreign Key                                                                 |
|               | `member_id`         | Foreign Key                                                                 |
|               | `rsvp_status`       | Enum (0=unanswered; 1=accepted; 2=declined)                                 |
|               | `responded_at` (UTC timestamp) | System generated creation timestamp                                       |

## Data Ingestion

* **Database Setup:** PostgreSQL is set up using Terraform, ensuring a consistent and reproducible database schema.
* **Containerization:** The entire ingestion process runs within a Docker container built on `python:3.12-slim-bookworm` for portability and isolation.

## Setup and Running Instructions

To set up and run the data ingestion process, follow these steps:

### 1. Prerequisites

Before you begin, ensure you have the following installed on your system:

* **Docker:** Used for containerizing the PostgreSQL database and the Python ingestion application.

#### Docker Permissions

If you encounter a `permission denied` error when running Docker commands (e.g., `docker: permission denied while trying to connect to the Docker daemon socket`), it means your user account doesn't have the necessary permissions.

To fix this:

1.  **Add your user to the `docker` group:**
    ```bash
    sudo usermod -aG docker $USER
    ```
2.  **Apply the new group membership:**
    You must either **log out and log back in** to your system, or **reboot** it, for the group changes to take effect.
3.  **Verify Docker is working (optional but recommended):**
    After logging back in, open a new terminal and run:
    ```bash
    docker run hello-world
    ```
    If you see a "Hello from Docker!" message, you're good to go.

### 2. Execution

Follow these steps from the terminal, in the root directory of `spond_project`:

* **Make the shell script executable:**
    ```bash
    chmod +x run_ingestion.sh
    ```

* **Run the ingestion script:**
    ```bash
    ./run_ingestion.sh
    ```

This script will perform the following actions:

1.  **Start a PostgreSQL Docker container:** A local PostgreSQL instance will be launched, accessible on `localhost:5432`.
2.  **Initialize and Apply Terraform:** Terraform will initialize its configuration and then apply `main.tf` to create the `spond_analytics` database and execute the `schema.sql` file to create the necessary tables, including their foreign key constraints.
3.  **Build Docker Image:** A Docker image named `spond-data-ingester` will be built, containing the Python ingestion script and its dependencies.
4.  **Run Ingestion Container:** The `spond-data-ingester` container will be run. It will connect to the local PostgreSQL database and ingest the data from the CSV files located in the `data` directory.
5.  **Completion Message:** You will see messages indicating the progress and completion of the data ingestion process.

### 3. Cleanup (Optional)

To stop and remove all the running services and files, you can run the following commands:

```bash
docker-compose down -v
```

### 4. Running Specific dbt Stages (Optional)

The `./run_ingestion.sh` script executes the full dbt `build` command, which includes running all models and all tests. However, you might want to run only specific parts of the dbt pipeline for development or debugging.

To do this, you can execute dbt commands directly within the `dbt-cli` Docker service. Ensure PostgreSQL container is running before attempting these commands (you can start it with `./run_ingestion.sh` and then `Ctrl+C` after the database is up, or manually with `docker-compose up -d postgres`).

Here are some common scenarios:

* **Run only Staging models:**
    This will execute all models located in `models/staging` directory.
    ```bash
    docker-compose run --rm dbt-cli dbt run --select path:models/staging
    ```

* **Run only Marts models:**
    This will execute all models located in `models/marts` directory. This command will likely fail if the necessary staging models (on which marts models depend) have not been run previously.
    ```bash
    docker-compose run --rm dbt-cli dbt run --select path:models/marts
    ```

* **Run only a specific model (e.g., `daily_active_teams`):**
    ```bash
    docker-compose run --rm dbt-cli dbt run --select daily_active_teams
    ```

* **Run all Tests:**
    This will execute all tests defined in `tests` directory.
    ```bash
    docker-compose run --rm dbt-cli dbt test
    ```

* **Run Tests for a specific model (e.g., `attendance_rate_30_days`):**
    ```bash
    docker-compose run --rm dbt-cli dbt test --select attendance_rate_30_days
    ```

* **Run only Staging models and their associated tests:**
    ```bash
    docker-compose run --rm dbt-cli dbt build --select path:models/staging
    ```

* **Run only Marts models and their associated tests:**
    ```bash
    docker-compose run --rm dbt-cli dbt build --select path:models/marts
    ```