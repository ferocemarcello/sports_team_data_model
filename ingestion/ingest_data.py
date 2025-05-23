import pandas as pd
import psycopg2
import os
from io import StringIO

def create_raw_table_if_not_exists(table_name, df_columns, cur):
    """
    Creates a raw table if it does not exist, inferring types from DataFrame columns.
    Uses TEXT for most columns for flexibility in raw ingestion.
    """
    column_defs = []
    for col in df_columns:
        # Simplified type inference for raw tables: mostly TEXT
        # Let dbt handle more precise casting in staging models
        if 'id' in col or 'code' in col or 'title' in col or 'name' in col or 'status' in col:
            pg_type = 'VARCHAR(255)' # IDs, codes, titles, names, statuses are often strings
        elif 'time' in col or 'date' in col:
            pg_type = 'TIMESTAMP' # For timestamps
        elif 'latitude' in col or 'longitude' in col:
            pg_type = 'NUMERIC' # For numeric coordinates
        elif 'is_admin' in col:
            pg_type = 'BOOLEAN'
        else:
            pg_type = 'TEXT' # Default to TEXT for everything else

        column_defs.append(f'"{col}" {pg_type}') # Quote column names to preserve case if needed, though pandas lowercases

    create_table_sql = f"""
    CREATE TABLE IF NOT EXISTS public.{table_name} (
        {', '.join(column_defs)}
    );
    """
    cur.execute(create_table_sql)
    print(f"Ensured table public.{table_name} exists.")


def ingest_csv_to_postgres(filepath, table_name, conn):
    """
    Ingests a CSV file into a PostgreSQL table.
    Ensures the raw table exists before ingesting.
    """
    try:
        df = pd.read_csv(filepath)
        print(f"Read {len(df)} rows from {filepath}")

        # Ensure column names are PostgreSQL-compatible (lowercase, no special chars)
        # IMPORTANT: Pandas reads headers as they are. The `df.columns` will be the exact header names.
        # PostgreSQL will lowercase unquoted identifiers. Our create_raw_table_if_not_exists
        # now quotes column names, so we should use the exact case from CSV header.
        # However, for consistency with dbt's default lowercasing, let's keep lowercasing here.
        # The key is that the `create_raw_table_if_not_exists` must match what pandas produces.
        df.columns = [col.lower().replace(' ', '_').replace('.', '_') for col in df.columns]


        with conn.cursor() as cur:
            # Create table if not exists based on CSV headers
            create_raw_table_if_not_exists(table_name, df.columns.tolist(), cur)

            # First, truncate the raw table to ensure idempotency for repeated runs
            cur.execute(f"TRUNCATE TABLE public.{table_name} RESTART IDENTITY;")
            print(f"Truncated table public.{table_name}.")

            # Use the copy_from method for efficient ingestion
            buffer = StringIO()
            df.to_csv(buffer, index=False, header=False)
            buffer.seek(0)

            cur.copy_from(buffer, f'public.{table_name}', sep=',')
            print(f"Successfully copied data to public.{table_name}.")
        conn.commit()

    except Exception as e:
        print(f"Error ingesting {filepath} to public.{table_name}: {e}")
        raise

if __name__ == "__main__":
    db_host = os.getenv('DB_HOST', 'db')
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'spond_analytics')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD', 'postgres')

    csv_files = {
        'teams': 'teams.csv',
        'memberships': 'memberships.csv',
        'events': 'events.csv',
        'event_rsvps': 'event_rsvps.csv', # This is the file for raw_event_rsvps
    }

    conn = None
    try:
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password
        )
        print("Connected to PostgreSQL successfully!")

        for table_name_key, filename in csv_files.items():
            filepath = f"/app/{filename}" # Path within the Docker container
            # Use the key from csv_files dict as the table name for PostgreSQL
            # This will create tables named 'teams', 'memberships', 'events', 'event_rsvps'
            ingest_csv_to_postgres(filepath, table_name_key, conn)

    except Exception as e:
        print(f"Database connection or ingestion failed: {e}")
        exit(1)
    finally:
        if conn:
            conn.close()
            print("PostgreSQL connection closed.")