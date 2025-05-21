import os
import pandas as pd
import psycopg2
from io import StringIO
import sys

def create_tables(cur):
    """Creates the necessary tables in the PostgreSQL database."""
    print("Creating tables...")
    # Teams table definition [cite: 14]
    cur.execute("""
        CREATE TABLE IF NOT EXISTS teams (
            team_id VARCHAR(255) PRIMARY KEY,
            group_activity VARCHAR(255),
            country_code CHAR(3),
            created_at BIGINT
        );
    """)
    print("Table 'teams' created or already exists.")

    # Members table definition [cite: 14]
    # Foreign Key: group_id references teams.team_id [cite: 16]
    cur.execute("""
        CREATE TABLE IF NOT EXISTS members (
            membership_id VARCHAR(255) PRIMARY KEY,
            group_id VARCHAR(255) REFERENCES teams(team_id),
            role_title VARCHAR(50),
            joined_at BIGINT
        );
    """)
    print("Table 'members' created or already exists.")

    # Events table definition [cite: 14]
    # Foreign Key: team_id references teams.team_id [cite: 16]
    cur.execute("""
        CREATE TABLE IF NOT EXISTS events (
            event_id VARCHAR(255) PRIMARY KEY,
            team_id VARCHAR(255) REFERENCES teams(team_id),
            event_start BIGINT,
            event_end BIGINT,
            created_at BIGINT
        );
    """)
    print("Table 'events' created or already exists.")

    # Event RSVPs table definition [cite: 14]
    # Foreign Keys: event_id references events.event_id, member_id references members.membership_id [cite: 16]
    cur.execute("""
        CREATE TABLE IF NOT EXISTS event_rsvps (
            event_rsvp_id VARCHAR(255) PRIMARY KEY,
            event_id VARCHAR(255) REFERENCES events(event_id),
            member_id VARCHAR(255) REFERENCES members(membership_id),
            rsvp_status SMALLINT, -- Enum (0=unanswered; 1=accepted; 2=declined) [cite: 14]
            responded_at BIGINT
        );
    """)
    print("Table 'event_rsvps' created or already exists.")

def ingest_csv_to_pg(cur, table_name, csv_file_path, column_names):
    """Ingests data from a CSV file into a specified PostgreSQL table."""
    print(f"Ingesting data into '{table_name}' from '{csv_file_path}'...")
    try:
        df = pd.read_csv(csv_file_path)
        
        # --- Handling Malformed Data (Example) --- [cite: 16]
        # This is a basic example. For production, more sophisticated error handling
        # like logging rejected rows or using a staging table might be necessary.
        if 'rsvp_status' in df.columns:
            # Convert rsvp_status to numeric, coercing errors to NaN, then fill NaN with -1
            # (or another designated 'malformed' value) and convert to int.
            df['rsvp_status'] = pd.to_numeric(df['rsvp_status'], errors='coerce').fillna(-1).astype(int) 

        # Prepare data for COPY FROM command
        # Convert DataFrame to a CSV string buffer without header or index for psycopg2.copy_from
        buffer = StringIO()
        df.to_csv(buffer, index=False, header=False)
        buffer.seek(0) # Rewind to the beginning of the buffer

        # Use copy_from for efficient bulk insertion
        cur.copy_from(buffer, table_name, sep=',', columns=column_names)
        print(f"Successfully ingested {len(df)} rows into '{table_name}'.")

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}")
        sys.exit(1)
    except pd.errors.EmptyDataError:
        print(f"Warning: CSV file {csv_file_path} is empty.")
    except Exception as e:
        print(f"Error ingesting data into '{table_name}': {e}")
        # In a real scenario, you might want to log the specific row that caused the error
        # or implement a more robust data quality check before ingestion.
        sys.exit(1)

def main():
    """Main function to establish DB connection and orchestrate data ingestion."""
    # Database connection details from environment variables
    # Default values are provided for local development with docker-compose
    pg_host = os.getenv('PG_HOST', 'localhost')
    pg_port = os.getenv('PG_PORT', '5432')
    pg_db = os.getenv('PG_DB', 'spond_db')
    pg_user = os.getenv('PG_USER', 'spond_user')
    pg_password = os.getenv('PG_PASSWORD', 'spond_password')

    conn = None
    try:
        print(f"Attempting to connect to PostgreSQL at host: {pg_host}, port: {pg_port}, database: {pg_db}...")
        conn = psycopg2.connect(
            host=pg_host,
            port=pg_port,
            dbname=pg_db,
            user=pg_user,
            password=pg_password
        )
        conn.autocommit = False # Use transactions for data integrity
        cur = conn.cursor()

        # Create tables (idempotent operation)
        create_tables(cur)

        # Ingest data from CSVs
        # Define column names explicitly to match table schema and CSV order
        ingest_csv_to_pg(cur, 'teams', './data/teams.csv', 
                         ['team_id', 'group_activity', 'country_code', 'created_at'])
        ingest_csv_to_pg(cur, 'members', './data/members.csv', 
                         ['membership_id', 'group_id', 'role_title', 'joined_at'])
        ingest_csv_to_pg(cur, 'events', './data/events.csv', 
                         ['event_id', 'team_id', 'event_start', 'event_end', 'created_at'])
        ingest_csv_to_pg(cur, 'event_rsvps', './data/event_rsvps.csv', 
                         ['event_rsvp_id', 'event_id', 'member_id', 'rsvp_status', 'responded_at'])

        # Commit all changes if ingestion was successful
        conn.commit() 
        print("Data ingestion complete and committed successfully.")

    except psycopg2.OperationalError as e:
        print(f"Database connection error: {e}")
        print("Please ensure the PostgreSQL database is running and accessible at the specified host and port.")
        sys.exit(1)
    except Exception as e:
        # Rollback in case of any error during ingestion
        if conn:
            conn.rollback()
            print("Transaction rolled back due to error.")
        print(f"An unexpected error occurred during ingestion: {e}")
        sys.exit(1)
    finally:
        if conn:
            cur.close()
            conn.close()
            print("PostgreSQL connection closed.")

if __name__ == "__main__":
    main()