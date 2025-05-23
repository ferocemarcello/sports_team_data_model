-- dbt/models/staging/stg_events.sql
SELECT
    event_id,
    team_id,
    event_start,
    event_end,
    latitude,
    longitude,
    created_at
FROM
    {{ source('public', 'raw_events') }}