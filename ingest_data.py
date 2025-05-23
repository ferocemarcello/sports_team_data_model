import csv
import json
import sqlite3
from datetime import datetime

DATABASE_FILE = 'data/spond_data.db'
SCHEMA_FILE = 'data/schema.sql'

def get_current_timestamp():
    """Returns the current Unix epoch timestamp in seconds."""
    return int(datetime.now().timestamp())

def parse_iso_timestamp(iso_string):
    """Parses an ISO 8601 timestamp string and returns Unix epoch seconds."""
    if not iso_string:
        return None
    # Remove 'Z' if present and parse
    dt_object = datetime.fromisoformat(iso_string.replace('Z', '+00:00'))
    return int(dt_object.timestamp())

def setup_database(conn):
    """Initializes the database schema."""
    with open(SCHEMA_FILE, 'r') as f:
        schema_sql = f.read()
    conn.executescript(schema_sql)
    conn.commit()

def ingest_teams(conn, csv_file_path):
    """Ingests data into the teams table."""
    cursor = conn.cursor()
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            team_id = row['team_id']
            # 'group_activity' from CSV maps to 'team_activity' in DB
            team_activity = row['team_activity']
            country_code = row['country_code']
            created_at = parse_iso_timestamp(row['created_at'])

            cursor.execute("""
                INSERT OR IGNORE INTO teams (team_id, team_activity, country_code, created_at)
                VALUES (?, ?, ?, ?)
            """, (team_id, team_activity, country_code, created_at))
    conn.commit()
    print(f"Ingested data into teams from {csv_file_path}")

def ingest_memberships(conn, csv_file_path):
    """Ingests data into the members table."""
    cursor = conn.cursor()
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            membership_id = row['membership_id']
            # 'group_id' from CSV maps to 'team_id' in DB
            team_id = row['group_id']
            role_title = row['role_title']
            joined_at = parse_iso_timestamp(row['joined_at'])

            cursor.execute("""
                INSERT OR IGNORE INTO members (membership_id, team_id, role_title, joined_at)
                VALUES (?, ?, ?, ?)
            """, (membership_id, team_id, role_title, joined_at))
    conn.commit()
    print(f"Ingested data into members from {csv_file_path}")

def ingest_events(conn, csv_file_path):
    """Ingests data into the events table."""
    cursor = conn.cursor()
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            event_id = row['event_id']
            team_id = row['team_id']
            event_start = parse_iso_timestamp(row['event_start'])
            event_end = parse_iso_timestamp(row['event_end'])
            created_at = parse_iso_timestamp(row['created_at'])
            
            # Handle new latitude and longitude fields, converting 'null' strings to None
            latitude = float(row['latitude']) if row['latitude'] and row['latitude'].lower() != 'null' else None
            longitude = float(row['longitude']) if row['longitude'] and row['longitude'].lower() != 'null' else None

            cursor.execute("""
                INSERT OR IGNORE INTO events (event_id, team_id, event_start, event_end, created_at, latitude, longitude)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (event_id, team_id, event_start, event_end, created_at, latitude, longitude))
    conn.commit()
    print(f"Ingested data into events from {csv_file_path}")

def ingest_event_rsvps(conn, csv_file_path):
    """Ingests data into the event_rsvps table."""
    cursor = conn.cursor()
    with open(csv_file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            event_rsvp_id = row['event_rsvp_id']
            event_id = row['event_id']
            member_id = row['membership_id'] # Note: CSV uses 'membership_id'
            rsvp_status = int(row['rsvp_status'])
            responded_at = parse_iso_timestamp(row['responded_at'])

            cursor.execute("""
                INSERT OR IGNORE INTO event_rsvps (event_rsvp_id, event_id, member_id, rsvp_status, responded_at)
                VALUES (?, ?, ?, ?, ?)
            """, (event_rsvp_id, event_id, member_id, rsvp_status, responded_at))
    conn.commit()
    print(f"Ingested data into event_rsvps from {csv_file_path}")

def main():
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_FILE)
        setup_database(conn)

        # Ingest data from the provided CSV files
        ingest_teams(conn, 'data/teams.csv')
        ingest_memberships(conn, 'data/memberships.csv')
        ingest_events(conn, 'data/events.csv')
        ingest_event_rsvps(conn, 'data/event_rsvps.csv')

        print("Data ingestion complete.")

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    except FileNotFoundError as e:
        print(f"File not found: {e}. Make sure CSV files and schema.sql are in the 'data/' directory.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()