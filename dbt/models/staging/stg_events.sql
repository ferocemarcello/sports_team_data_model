-- dbt/models/staging/stg_events.sql
SELECT
    -- Cast IDs to INT, filtering out non-numeric values
    CASE WHEN events.event_id ~ '^[0-9]+$' THEN events.event_id::INT ELSE NULL END AS event_id,
    CASE WHEN events.team_id ~ '^[0-9]+$' THEN events.team_id::INT ELSE NULL END AS team_id,
    -- Safely convert event_time to epoch seconds since 1970-01-01 00:00:00 UTC
    CASE WHEN events.event_start ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$'
    THEN EXTRACT(EPOCH FROM (events.event_start::TIMESTAMPTZ))::BIGINT -- <--- CHANGED
    ELSE NULL
    END AS event_start,
    -- Safely convert event_end to epoch seconds since 1970-01-01 00:00:00 UTC
    CASE WHEN events.event_end ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$'
    THEN EXTRACT(EPOCH FROM (events.event_end::TIMESTAMPTZ))::BIGINT -- <--- CHANGED
    ELSE NULL
    END AS event_end,
    CASE WHEN events.latitude ~ '^-?\d+(\.\d+)?$' THEN events.latitude::NUMERIC ELSE NULL END AS latitude,
    CASE WHEN events.longitude ~ '^-?\d+(\.\d+)?$' THEN events.longitude::NUMERIC ELSE NULL END AS longitude,
    CASE WHEN events.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$'
    THEN EXTRACT(EPOCH FROM (events.created_at::TIMESTAMPTZ))::BIGINT
    ELSE NULL
    END AS created_at
FROM
    {{ ref('events') }} AS events
WHERE
    -- Filter out rows where IDs are not valid INTs
    (CASE WHEN events.event_id ~ '^[0-9]+$' THEN events.event_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.team_id ~ '^[0-9]+$' THEN events.team_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.event_start ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_start::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.event_end ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_end::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.latitude ~ '^-?\d+(\.\d+)?$' THEN events.latitude::NUMERIC ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.longitude ~ '^-?\d+(\.\d+)?$' THEN events.longitude::NUMERIC ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.event_end ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_end::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.created_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL