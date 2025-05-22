import pandas as pd
import psycopg2
from psycopg2 import Error
import os
from datetime import datetime

# Database connection details
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "spond_analytics")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres") # Replace with a strong password or secret management

def get_db_connection():
    """Establishes and returns a database connection."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except Error as e:
        print(f"Error connecting to PostgreSQL: {e}")
        raise

def to_unix_timestamp_seconds(utc_timestamp_str):
    """Converts a UTC timestamp string to Unix timestamp (seconds from epoch)."""
    if pd.isna(utc_timestamp_str):
        return None
    try:
        # Assuming input format is 'YYYY-MM-DD HH:MM:SS.f+00:00' or similar
        # datetime.fromisoformat handles various ISO 8601 formats
        dt_object = datetime.fromisoformat(utc_timestamp_str.replace('Z', '+00:00'))
        return int(dt_object.timestamp())
    except ValueError as e:
        print(f"Warning: Could not parse timestamp '{utc_timestamp_str}': {e}")
        return None # Handle malformed data by returning None

def ingest_data(conn, cursor, file_path, table_name, column_mapping, timestamp_columns):
    """
    Ingests data from a CSV file into a specified PostgreSQL table.
    Handles data type conversions and malformed data.
    """
    print(f"Ingesting data from {file_path} into {table_name}...")
    try:
        df = pd.read_csv(file_path)

        # Rename columns to match database schema if necessary (based on column_mapping)
        df = df.rename(columns=column_mapping)

        # Convert specified timestamp columns to Unix timestamp (seconds)
        for col in timestamp_columns:
            if col in df.columns:
                df[col] = df[col].apply(to_unix_timestamp_seconds)

        # Prepare data for insertion
        # Ensure column order matches the table schema for copy_from
        # This requires knowing the exact column order in the table, or specifying it
        # For simplicity, we'll assume the dataframe columns are ordered correctly or adjust.
        # A more robust solution might dynamically fetch column names from the DB schema.

        # Filter out rows with None for critical columns if necessary, or handle in DB
        # For this example, we'll let psycopg2 handle None for nullable columns.

        # Convert DataFrame to a list of tuples for insertion
        # Ensure the order of columns matches the order in your SQL INSERT statement
        # or the table definition for copy_from
        
        # Example for `teams` table
        if table_name == "teams":
            columns = ["team_id", "group_activity", "country_code", "created_at"]
        elif table_name == "members":
            columns = ["membership_id", "group_id", "role_title", "joined_at"]
        elif table_name == "events":
            columns = ["event_id", "team_id", "event_start", "event_end", "created_at"]
        elif table_name == "event_rsvps":
            columns = ["event_rsvp_id", "event_id", "member_id", "rsvp_status", "responded_at"]
        else:
            raise ValueError(f"Unknown table name: {table_name}")

        # Reorder DataFrame columns to match the expected order for insertion
        df_to_insert = df[columns]

        # Handle NaN values for non-string types that might cause issues (e.g., int columns)
        # For 'rsvp_status', which is INTEGER, ensure NaN is converted to None for SQL NULL
        if table_name == "event_rsvps":
            df_to_insert['rsvp_status'] = df_to_insert['rsvp_status'].fillna(0).astype(int) # Assuming 0 for unanswered for now if NaN
            # Or simpler: df_to_insert['rsvp_status'] = df_to_insert['rsvp_status'].replace({float('nan'): None})

        # Convert DataFrame to a list of tuples, handling None for NaN/NaT
        data_to_insert = [tuple(row.apply(lambda x: None if pd.isna(x) else x)) for index, row in df_to_insert.iterrows()]

        # Using psycopg2.extras.execute_values for efficient bulk insertion
        # Or you can use a temporary file with copy_from for very large datasets
        
        # Create a string of placeholders for the INSERT statement
        placeholders = ', '.join(['%s'] * len(columns))
        insert_statement = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"

        # Execute insertion
        cursor.executemany(insert_statement, data_to_insert)
        conn.commit()
        print(f"Successfully ingested {len(data_to_insert)} rows into {table_name}.")

    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
    except pd.errors.EmptyDataError:
        print(f"Warning: {file_path} is empty. No data to ingest.")
    except Exception as e:
        conn.rollback() # Rollback on error
        print(f"Error ingesting data into {table_name}: {e}")
        raise

if __name__ == "__main__":
    # Create a 'data' directory and place your CSVs there
    # For local testing, ensure these CSVs are in the 'data' directory
    # relative to where the script runs, or adjust paths.
    csv_dir = os.path.join(os.path.dirname(__file__), "data")

    # Define files, their corresponding tables, and timestamp columns
    ingestion_plan = [
        {
            "file": os.path.join(csv_dir, "teams.csv"),
            "table": "teams",
            "column_map": {}, # No column renaming needed if CSV headers match DB columns
            "timestamp_cols": ["created_at"]
        },
        {
            "file": os.path.join(csv_dir, "members.csv"),
            "table": "members",
            "column_map": {},
            "timestamp_cols": ["joined_at"]
        },
        {
            "file": os.path.join(csv_dir, "events.csv"),
            "table": "events",
            "column_map": {},
            "timestamp_cols": ["event_start", "event_end", "created_at"]
        },
        {
            "file": os.path.join(csv_dir, "event_rsvps.csv"),
            "table": "event_rsvps",
            "column_map": {},
            "timestamp_cols": ["responded_at"]
        }
    ]

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Ingest data in order to respect foreign key constraints
        # teams -> members, events -> event_rsvps
        # This order is important for foreign key integrity
        for item in ingestion_plan:
            ingest_data(
                conn,
                cursor,
                item["file"],
                item["table"],
                item["column_map"],
                item["timestamp_cols"]
            )
        print("Data ingestion complete.")

    except Exception as e:
        print(f"An error occurred during the ingestion process: {e}")
    finally:
        if conn:
            cursor.close()
            conn.close()
            print("Database connection closed.")
