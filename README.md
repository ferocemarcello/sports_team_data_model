# Spond Data Ingestion Project

This project demonstrates a solution for ingesting and transforming data about members, teams, and events for analytics, focusing on data ingestion, modeling, and foundational aspects for production readiness.

## Project Structure

```
spond_project/
├── data/
│   ├── teams.csv
│   ├── members.csv
│   ├── events.csv
│   └── event_rsvps.csv
├── terraform/
│   └── main.tf
├── Dockerfile
├── requirements.txt
├── ingest_data.py
└── run_ingestion.sh
```

## Data Description

The project utilizes three sample datasets in CSV format: `teams`, `members`, `events`, and `event_rsvps`. The schema for these tables is as follows:

| Table         | Column              | Description                                                                 |
|---------------|---------------------|-----------------------------------------------------------------------------|
| `teams`       | `team_id` (string)  | Unique ID                                                                   |
|               | `group_activity` (string) | Activity type of group e.g., football, cricket, rugby, etc.           |
|               | `country_code` (string) | Alpha-3 country code of group e.g., NOR=Norway; GBR=United Kingdom; etc. |
|               | `created_at` (UTC timestamp) | System generated creation timestamp                                       |
| `members`     | `membership_id`     | Unique ID                                                                   |
|               | `group_id`          | Foreign Key (references `teams.team_id`)                                    |
|               | `role_title` (string) | member or admin                                                             |
|               | `joined_at` (UTC timestamp) | System generated creation timestamp                                       |
| `events`      | `event_id`          | Unique ID                                                                   |
|               | `team_id`           | Foreign Key (references `teams.team_id`)                                    |
|               | `event_start` (UTC timestamp) | User-defined event start timestamp                                          |
|               | `event_end` (UTC timestamp)   | User-defined event end timestamp                                            |
|               | `created_at` (UTC timestamp) | System generated creation timestamp                                       |
| `event_rsvps` | `event_rsvp_id`     | Unique ID                                                                   |
|               | `event_id`          | Foreign Key (references `events.event_id`)                                  |
|               | `member_id`         | Foreign Key (references `members.membership_id`)                            |
|               | `rsvp_status`       | Enum (0=unanswered; 1=accepted; 2=declined)                                 |
|               | `responded_at` (UTC timestamp) | System generated creation timestamp                                       |

## Data Ingestion

The aim of this section is to ingest the provided CSV data into a local PostgreSQL database. Key considerations for ingestion include:
* **Timestamp Transformation:** All timestamps are converted to the number of seconds from 01/01/1970.
* **Foreign Key Handling:** The `group_id` in the `members` table correctly references the `team_id` in the `teams` table, and similar relationships are maintained for `events` and `event_rsvps`.
* **Database Setup:** PostgreSQL is set up using Terraform, ensuring a consistent and reproducible database schema.
* **Containerization:** The entire ingestion process runs within a Docker container built on `python:3.12-slim-bookworm` for portability and isolation.

## Setup and Running Instructions

To set up and run the data ingestion process, follow these steps:

### 1. Prerequisites

Before you begin, ensure you have the following installed on your system:

* **Docker:** Used for containerizing the PostgreSQL database and the Python ingestion application.
* **Terraform:** Used for provisioning the PostgreSQL database and tables.
* **Python 3.12.x:** While the main execution happens in a Docker container, having Python locally can be useful for development and testing.

### 2. Project Structure

Ensure your project directory is organized as described in the "Project Structure" section above. Specifically, place your sample CSV files (`teams.csv`, `members.csv`, `events.csv`, `event_rsvps.csv`) inside the `data/` subdirectory.

### 3. Execution

Follow these steps from your terminal, in the root directory of your `spond_project`:

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
2.  **Initialize and Apply Terraform:** Terraform will initialize its configuration and then apply `main.tf` to create the `spond_analytics` database and the necessary tables (`teams`, `members`, `events`, `event_rsvps`), including their foreign key constraints.
3.  **Build Docker Image:** A Docker image named `spond-data-ingester` will be built, containing the Python ingestion script and its dependencies.
4.  **Run Ingestion Container:** The `spond-data-ingester` container will be run. It will connect to the local PostgreSQL database and ingest the data from the CSV files located in the `data` directory.
5.  **Completion Message:** You will see messages indicating the progress and completion of the data ingestion process.

### 4. Verification (Optional)

After the script finishes, you can optionally connect to the PostgreSQL database to verify that the data has been successfully loaded:

* **Connect to PostgreSQL using `psql`:**
    ```bash
    psql -h localhost -p 5432 -U postgres -d spond_analytics
    ```
    (You might be prompted for the password, which is `postgres` as configured in the `run_ingestion.sh` script).

* **Run sample queries to check data counts:**
    ```sql
    SELECT COUNT(*) FROM teams;
    SELECT COUNT(*) FROM members;
    SELECT COUNT(*) FROM events;
    SELECT COUNT(*) FROM event_rsvps;
    ```

### 5. Cleanup (Optional)

To stop and remove the PostgreSQL container after you are done with verification, you can run the following commands:

```bash
docker stop spond-postgres
docker rm spond-postgres