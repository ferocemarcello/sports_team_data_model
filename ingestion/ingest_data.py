import pandas as pd
import psycopg2
import os
from io import StringIO

def create_raw_table_if_not_exists(table_name, df_columns, cur):
    """
    Creates a raw table if it does not exist, inferring types from DataFrame columns.
    """
    column_defs = []
    for col in df_columns:
        # Simple type inference (you might want more robust type mapping)
        if 'id' in col:
            pg_type = 'VARCHAR(255)' # Assuming IDs might be UUIDs or strings
        elif 'time' in col or 'date' in col:
            pg_type = 'TIMESTAMP'
        elif 'is_admin' in col:
            pg_type = 'BOOLEAN'
        else:
            pg_type = 'TEXT' # Default to TEXT for other columns

        column_defs.append(f"{col} {pg_type}")

    create_table_sql = f"""
    CREATE TABLE IF NOT EXISTS raw_{table_name} (
        {', '.join(column_defs)}
    );
    """
    cur.execute(create_table_sql)
    print(f"Ensured table raw_{table_name} exists.")


def ingest_csv_to_postgres(filepath, table_name, conn):
    """
    Ingests a CSV file into a PostgreSQL table.
    Ensures the raw table exists before ingesting.
    """
    try:
        df = pd.read_csv(filepath)
        print(f"Read {len(df)} rows from {filepath}")

        # Ensure column names are PostgreSQL-compatible (lowercase, no special chars)
        original_columns = df.columns
        df.columns = [col.lower().replace(' ', '_').replace('.', '_') for col in df.columns]

        with conn.cursor() as cur:
            # Create table if not exists based on CSV headers
            create_raw_table_if_not_exists(table_name, df.columns.tolist(), cur)

            # First, truncate the raw table to ensure idempotency for repeated runs
            cur.execute(f"TRUNCATE TABLE raw_{table_name} RESTART IDENTITY;")
            print(f"Truncated table raw_{table_name}.")

            # Use the copy_from method for efficient ingestion
            buffer = StringIO()
            df.to_csv(buffer, index=False, header=False)
            buffer.seek(0)

            cur.copy_from(buffer, f'raw_{table_name}', sep=',')
            print(f"Successfully copied data to raw_{table_name}.")
        conn.commit()

    except Exception as e:
        print(f"Error ingesting {filepath} to raw_{table_name}: {e}")
        raise

if __name__ == "__main__":
    db_host = os.getenv('DB_HOST', 'db') # 'db' is the service name within docker-compose network
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'spond_analytics')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD', 'postgres')

    csv_files = {
        'teams': 'teams.csv',
        'memberships': 'memberships.csv',
        'events': 'events.csv',
        'event_rsvps': 'event_rsvps.csv',
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

        for table_name, filename in csv_files.items():
            filepath = f"/app/{filename}" # Path within the Docker container
            ingest_csv_to_postgres(filepath, table_name, conn)

    except Exception as e:
        print(f"Database connection or ingestion failed: {e}")
        exit(1)
    finally:
        if conn:
            conn.close()
            print("PostgreSQL connection closed.")