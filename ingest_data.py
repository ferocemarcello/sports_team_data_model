import psycopg2
import pandas as pd
import os
from datetime import datetime

# Database connection parameters - use host and port
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "spond_analytics")
DB_USER = os.getenv("DB_USER", "user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")

def connect_db():
    """Establishes a connection to the PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        print(f"Successfully connected to PostgreSQL at {DB_HOST}:{DB_PORT}")
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL: {e}")
        exit(1)

def create_tables(cur):
    """Creates tables in the database, handling foreign keys and data types."""
    print("Creating tables...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS teams (
            team_id VARCHAR PRIMARY KEY,
            group_activity VARCHAR,
            country_code VARCHAR,
            created_at BIGINT
        );
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS members (
            membership_id VARCHAR PRIMARY KEY,
            group_id VARCHAR,
            role_title VARCHAR,
            joined_at BIGINT
        );
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS events (
            event_id VARCHAR PRIMARY KEY,
            team_id VARCHAR REFERENCES teams(team_id),
            event_start BIGINT,
            event_end BIGINT,
            created_at BIGINT
        );
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS event_rsvps (
            event_rsvp_id VARCHAR PRIMARY KEY,
            event_id VARCHAR REFERENCES events(event_id),
            member_id VARCHAR REFERENCES members(membership_id),
            rsvp_status INTEGER,
            responded_at BIGINT
        );
    """)
    print("Tables created or already exist.")

def ingest_csv(cur, file_path, table_name, columns_mapping, timestamp_cols):
    """
    Ingests data from a CSV file into the specified table.
    Handles timestamp conversion and basic malformed data (by skipping rows with errors).
    """
    print(f"Ingesting data from {file_path} into {table_name}...")
    try:
        df = pd.read_csv(file_path)

        # Convert specified timestamp columns to Unix seconds (from 01/01/1970)
        for col in timestamp_cols:
            if col in df.columns:
                # Attempt to convert to datetime, coercing errors will turn invalid dates into NaT
                df[col] = pd.to_datetime(df[col], errors='coerce', utc=True)
                # Convert to Unix timestamp (seconds since epoch) and handle NaT
                df[col] = df[col].apply(lambda x: int(x.timestamp()) if pd.notna(x) else None)

        # Prepare data for insertion
        # Ensure column order matches the table definition
        cols = ','.join(columns_mapping.keys())
        # Use a list of tuples for psycopg2.extras.execute_values
        values = []
        for index, row in df.iterrows():
            try:
                row_values = [row[col_csv] for col_csv in columns_mapping.values()]
                values.append(tuple(row_values))
            except KeyError as e:
                print(f"Skipping row {index} in {file_path} due to missing column: {e}")
            except Exception as e:
                print(f"Skipping row {index} in {file_path} due to unexpected error: {e}")

        # Construct the INSERT statement
        insert_statement = f"INSERT INTO {table_name} ({cols}) VALUES %s ON CONFLICT DO NOTHING;" # ON CONFLICT DO NOTHING to handle potential duplicate IDs
        
        from psycopg2.extras import execute_values
        execute_values(cur, insert_statement, values, page_size=1000)
        print(f"Successfully ingested {len(values)} rows into {table_name}.")

    except FileNotFoundError:
        print(f"Error: {file_path} not found.")
    except pd.errors.EmptyDataError:
        print(f"Warning: {file_path} is empty.")
    except Exception as e:
        print(f"Error ingesting data from {file_path}: {e}")

def main():
    conn = connect_db()
    cur = conn.cursor()

    create_tables(cur)

    # Define column mappings and timestamp columns for each table
    teams_cols = {"team_id": "team_id", "group_activity": "group_activity", "country_code": "country_code", "created_at": "created_at"}
    members_cols = {"membership_id": "membership_id", "group_id": "group_id", "role_title": "role_title", "joined_at": "joined_at"}
    events_cols = {"event_id": "event_id", "team_id": "team_id", "event_start": "event_start", "event_end": "event_end", "created_at": "created_at"}
    event_rsvps_cols = {"event_rsvp_id": "event_rsvp_id", "event_id": "event_id", "member_id": "member_id", "rsvp_status": "rsvp_status", "responded_at": "responded_at"}

    ingest_csv(cur, './data/teams.csv', 'teams', teams_cols, ['created_at'])
    # Ingest members after teams, as events refer to teams but members do not directly refer to teams
    ingest_csv(cur, './data/members.csv', 'members', members_cols, ['joined_at'])
    ingest_csv(cur, './data/events.csv', 'events', events_cols, ['event_start', 'event_end', 'created_at'])
    ingest_csv(cur, './data/event_rsvps.csv', 'event_rsvps', event_rsvps_cols, ['responded_at'])

    conn.commit()
    cur.close()
    conn.close()
    print("Data ingestion complete.")

if __name__ == "__main__":
    main()