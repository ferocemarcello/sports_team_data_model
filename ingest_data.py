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

    for statement in schema_sql.split(';'):
        if statement.strip():
            try:
                cursor.execute(statement)
            except psycopg2.Error as e:
                if 'already exists' in str(e) and 'CREATE TABLE IF NOT EXISTS' in statement:
                    print(f"Table already exists, skipping: {statement.strip().splitlines()[0]}...")
                    conn.rollback()
                else:
                    print(f"Error executing schema statement: {statement.strip()}")
                    raise e
    print("Attempting to commit database schema.") # New print
    conn.commit()
    print("Database schema committed.") # New print
    cursor.close()
    print("Database schema initialized (or verified if tables existed).")


def ingest_data_from_csv(conn, csv_file_path, table_name, columns_mapping, timestamp_cols):
    """Generic function to ingest data from a CSV into a specified table."""
    cursor = conn.cursor()
    ingested_rows = 0
    skipped_fk_violations = 0
    skipped_other_db_errors = 0
    skipped_general_errors = 0

    pk_col_name_csv = next(iter(columns_mapping))
    pk_col_name_db = columns_mapping[pk_col_name_csv][0]


    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            try:
                values = []
                for csv_col, db_col_info in columns_mapping.items():
                    db_col_name = db_col_info[0]
                    col_type = db_col_info[1]

                    value = row.get(csv_col)

                    if db_col_name in timestamp_cols:
                        values.append(parse_iso_timestamp(value))
                    elif col_type == 'int':
                        values.append(int(value) if value else None)
                    elif col_type == 'float':
                        values.append(float(value) if value and value.lower() != 'null' else None)
                    else:
                        values.append(value)

                db_column_names = [info[0] for info in columns_mapping.values()]
                placeholders = ', '.join(['%s'] * len(db_column_names))
                insert_sql = f"INSERT INTO {table_name} ({', '.join(db_column_names)}) VALUES ({placeholders}) ON CONFLICT DO NOTHING;"

                cursor.execute(insert_sql, values)
                ingested_rows += 1

            except psycopg2.errors.ForeignKeyViolation as e:
                skipped_fk_violations += 1
                conn.rollback()
                continue
            except psycopg2.Error as e:
                print(f"--- Error ingesting row {i+1} into {table_name} from {csv_file_path} ---")
                print(f"  Row PK ({pk_col_name_db}): {row.get(pk_col_name_csv)}")
                print(f"  PostgreSQL Error Code: {e.pgcode}")
                print(f"  PostgreSQL Error Message: {e.pgerror.strip()}")
                print(f"  Problematic row data: {row}")
                print("--------------------------------------------------")
                skipped_other_db_errors += 1
                conn.rollback()
                continue
            except Exception as e:
                print(f"--- Unexpected Error ingesting row {i+1} into {table_name} from {csv_file_path} ---")
                print(f"  Row PK ({pk_col_name_db}): {row.get(pk_col_name_csv)}")
                print(f"  Error Type: {type(e).__name__}")
                print(f"  Error Message: {e}")
                print(f"  Problematic row data: {row}")
                print("--------------------------------------------------")
                skipped_general_errors += 1
                conn.rollback()
                continue

    print(f"Attempting to commit data for {table_name}.") # New print
    conn.commit()
    print(f"Data for {table_name} committed to database.") # New print
    cursor.close()
    print(f"Successfully ingested {ingested_rows} rows into {table_name} from {csv_file_path}.")
    if skipped_fk_violations > 0:
        print(f"  Skipped {skipped_fk_violations} rows due to Foreign Key violations.")
    if skipped_other_db_errors > 0:
        print(f"  Skipped {skipped_other_db_errors} rows due to other database errors.")
    if skipped_general_errors > 0:
        print(f"  Skipped {skipped_general_errors} rows due to general errors.")
    total_skipped = skipped_fk_violations + skipped_other_db_errors + skipped_general_errors
    if total_skipped > 0:
        print(f"  Total skipped rows: {total_skipped}.")


def main():
    conn = None
    try:
        conn = get_db_connection()

        setup_database(conn)

        # Define column mappings for each table
        teams_cols = {
            'team_id': ('team_id', 'str'),
            'team_activity': ('team_activity', 'str'),
            'country_code': ('country_code', 'str'),
            'created_at': ('created_at', 'timestamp')
        }
        memberships_cols = {
            'membership_id': ('membership_id', 'str'),
            'team_id': ('team_id', 'str'),
            'role_title': ('role_title', 'str'),
            'joined_at': ('joined_at', 'timestamp')
        }
        events_cols = {
            'event_id': ('event_id', 'str'),
            'team_id': ('team_id', 'str'),
            'event_start': ('event_start', 'timestamp'),
            'event_end': ('event_end', 'timestamp'),
            'created_at': ('created_at', 'timestamp'),
            'latitude': ('latitude', 'float'),
            'longitude': ('longitude', 'float')
        }
        event_rsvps_cols = {
            'event_rsvp_id': ('event_rsvp_id', 'str'),
            'event_id': ('event_id', 'str'),
            'membership_id': ('member_id', 'str'),
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