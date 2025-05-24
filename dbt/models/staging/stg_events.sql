-- dbt/models/staging/stg_events.sql
SELECT
    events.event_id AS event_id,
    events.team_id AS team_id,
    EXTRACT(EPOCH FROM events.event_start)::BIGINT AS event_start,
    EXTRACT(EPOCH FROM events.event_end)::BIGINT AS event_end,
    events.latitude,
    events.longitude,
    EXTRACT(EPOCH FROM events.created_at)::BIGINT AS created_at
FROM
    {{ ref('events') }} AS events
WHERE
    events.event_id IS NOT NULL AND
    events.team_id IS NOT NULL AND