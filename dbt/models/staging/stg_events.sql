-- dbt/models/staging/stg_events.sql
SELECT
    event_id,
    team_id,
    -- event_name, -- This column is not directly in events.csv
    event_start AS event_time, -- Assuming event_start maps to event_time
    event_end,
    latitude,
    longitude,
    created_at
    -- location -- This column is not directly in events.csv, might be derived from lat/long
FROM
    {{ source('public', 'raw_events') }}