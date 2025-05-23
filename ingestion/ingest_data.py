import pandas as pd
import psycopg2
import os
from io import StringIO

# ... (create_raw_table_if_not_exists function remains the same) ...

def ingest_csv_to_postgres(filepath, table_name, conn):
    """
    Ingests a CSV file into a PostgreSQL table.
    Ensures the raw table exists before ingesting.
    """
    try:
        df = pd.read_csv(filepath)
        print(f"Read {len(df)} rows from {filepath}")

        df.columns = [col.lower().replace(' ', '_').replace('.', '_') for col in df.columns]

        with conn.cursor() as cur:
            # Create table if not exists based on CSV headers
            create_raw_table_if_not_exists(table_name, df.columns.tolist(), cur)

            # First, truncate the raw table to ensure idempotency for repeated runs
            cur.execute(f"TRUNCATE TABLE public.{table_name} RESTART IDENTITY;")
            print(f"Truncated table public.{table_name}.")

            # Commit DDL operations immediately
            conn.commit()
            print(f"Committed table creation and truncation for public.{table_name}.")

            # --- Verification step (keep this for now) ---
            try:
                cur.execute(f"SELECT 1 FROM public.{table_name} LIMIT 1;")
                print(f"Verification: Table public.{table_name} is accessible before COPY.")
            except psycopg2.Error as e:
                print(f"Verification FAILED: Table public.{table_name} is NOT accessible before COPY. Error: {e}")
                raise
            # --- END Verification step ---


            # --- CRITICAL CHANGE: Use copy_expert instead of copy_from ---
            sql_copy = f"""
            COPY public.{table_name} FROM STDIN WITH (FORMAT CSV, HEADER FALSE);
            """
            # Note: HEADER FALSE is essential because df.to_csv(header=False) writes no header

            buffer = StringIO()
            df.to_csv(buffer, index=False, header=False) # Ensure no header is written to buffer
            buffer.seek(0)

            cur.copy_expert(sql_copy, buffer) # Use copy_expert with the SQL command and the buffer
            print(f"Successfully copied data to public.{table_name}.")

        # Commit the COPY operation
        conn.commit()

    except Exception as e:
        print(f"Error ingesting {filepath} to public.{table_name}: {e}")
        raise

# ... (main function remains the same) ...