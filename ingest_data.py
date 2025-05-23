import csv
import os
import psycopg2
from datetime import datetime

# Database connection details from environment variables
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'spond_analytics')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')

SCHEMA_FILE = 'data/schema.sql'

def get_db_connection():
    """Establishes and returns a PostgreSQL database connection."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        print("Successfully connected to PostgreSQL.")
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL: {e}")
        raise

def parse_iso_timestamp(iso_string):
    """Parses an ISO 8601 timestamp string and returns Unix epoch seconds."""
    if not iso_string:
        return None
    try:
        # datetime.fromisoformat handles various ISO 8601 formats, including 'Z' and timezone offsets.
        dt_object = datetime.fromisoformat(iso_string.replace('Z', '+00:00'))
        return int(dt_object.timestamp())
    except ValueError as e:
        print(f"Warning: Could not parse timestamp '{iso_string}': {e}")
        return None


def setup_database(conn):
    """Initializes the database schema."""
    cursor = conn.cursor()
    with open(SCHEMA_FILE, 'r') as f:
        schema_sql = f.read()
    
    # Execute each statement separately
    # This is important for psycopg2 which doesn't support multiple statements directly with execute()
    # It also helps catch errors in individual statements.
    for statement in schema_sql.split(';'):
        if statement.strip(): # Ensure not to execute empty statements
            try:
                cursor.execute(statement)
            except psycopg2.Error as e:
                # Catch specific error for "relation already exists" from IF NOT EXISTS
                if 'already exists' in str(e) and 'CREATE TABLE IF NOT EXISTS' in statement:
                    print(f"Table already exists, skipping: {statement.strip().splitlines()[0]}...")
                    conn.rollback() # Rollback the current transaction if an error occurs
                else:
                    print(f"Error executing schema statement: {statement.strip()}")
                    raise e
    conn.commit()
    cursor.close()
    print("Database schema initialized (or verified if tables existed).")


def ingest_data_from_csv(conn, csv_file_path, table_name, columns_mapping, timestamp_cols):
    """Generic function to ingest data from a CSV into a specified table."""
    cursor = conn.cursor()
    ingested_rows = 0
    skipped_rows = 0

    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            try:
                # Prepare data for insertion
                values = []
                for csv_col, db_col_info in columns_mapping.items():
                    db_col_name = db_col_info[0]
                    col_type = db_col_info[1] # e.g., 'str', 'int', 'float', 'timestamp'

                    value = row.get(csv_col)

                    if db_col_name in timestamp_cols:
                        values.append(parse_iso_timestamp(value))
                    elif col_type == 'int':
                        values.append(int(value) if value else None)
                    elif col_type == 'float':
                        # Handle 'null' string from CSV or empty strings
                        values.append(float(value) if value and value.lower() != 'null' else None)
                    else: # Default to string
                        values.append(value)
                
                # Construct INSERT statement dynamically
                db_column_names = [info[0] for info in columns_mapping.values()]
                placeholders = ', '.join(['%s'] * len(db_column_names))
                insert_sql = f"INSERT INTO {table_name} ({', '.join(db_column_names)}) VALUES ({placeholders}) ON CONFLICT DO NOTHING;"
                
                cursor.execute(insert_sql, values)
                ingested_rows += 1

            except Exception as e:
                print(f"Error ingesting row {i+1} from {csv_file_path} into {table_name}: {e}")
                print(f"Problematic row: {row}")
                skipped_rows += 1
                conn.rollback() # Rollback the current transaction for this row to continue with next
                continue # Continue to the next row

    conn.commit()
    cursor.close()
    print(f"Successfully ingested {ingested_rows} rows into {table_name} from {csv_file_path}.")
    if skipped_rows > 0:
        print(f"Skipped {skipped_rows} rows due to errors in {csv_file_path}.")


def main():
    conn = None
    try:
        conn = get_db_connection()
        
        # Setup database schema - this will re-create tables if they don't exist
        # or if the schema hash in terraform.tfstate changes.
        setup_database(conn)

        # Define column mappings for each table
        teams_cols = {
            'team_id': ('team_id', 'str'),
            'team_activity': ('team_activity', 'str'), # Renamed from group_activity
            'country_code': ('country_code', 'str'),
            'created_at': ('created_at', 'timestamp')
        }
        memberships_cols = { # Table renamed to memberships
            'membership_id': ('membership_id', 'str'),
            'group_id': ('team_id', 'str'), # CSV 'group_id' maps to DB 'team_id'
            'role_title': ('role_title', 'str'),
            'joined_at': ('joined_at', 'timestamp')
        }
        events_cols = {
            'event_id': ('event_id', 'str'),
            'team_id': ('team_id', 'str'),
            'event_start': ('event_start', 'timestamp'),
            'event_end': ('event_end', 'timestamp'),
            'created_at': ('created_at', 'timestamp'),
            'latitude': ('latitude', 'float'), # New column
            'longitude': ('longitude', 'float') # New column
        }
        event_rsvps_cols = {
            'event_rsvp_id': ('event_rsvp_id', 'str'),
            'event_id': ('event_id', 'str'),
            'membership_id': ('member_id', 'str'), # CSV 'membership_id' maps to DB 'member_id'
            'rsvp_status': ('rsvp_status', 'int'),
            'responded_at': ('responded_at', 'timestamp')
        }

        # List of columns that require timestamp parsing
        timestamp_columns = ['created_at', 'joined_at', 'event_start', 'event_end', 'responded_at']

        # Ingest data using the generic function
        ingest_data_from_csv(conn, 'data/teams.csv', 'teams', teams_cols, timestamp_columns)
        ingest_data_from_csv(conn, 'data/memberships.csv', 'memberships', memberships_cols, timestamp_columns)
        ingest_data_from_csv(conn, 'data/events.csv', 'events', events_cols, timestamp_columns)
        ingest_data_from_csv(conn, 'data/event_rsvps.csv', 'event_rsvps', event_rsvps_cols, timestamp_columns)

        print("\nData ingestion complete.")

    except psycopg2.Error as e:
        print(f"\nDatabase error during main execution: {e}")
    except FileNotFoundError as e:
        print(f"\nFile not found error: {e}. Make sure CSV files and schema.sql are in the 'data/' directory.")
    except Exception as e:
        print(f"\nAn unexpected error occurred during main execution: {e}")
    finally:
        if conn:
            conn.close()
            print("Database connection closed.")

if __name__ == "__main__":
    main()