-- dbt/models/staging/stg_events.sql
SELECT
    -- Use CASE for robust type casting
    CASE WHEN events.event_id ~ '^[0-9A-Za-z-]+$' THEN events.event_id ELSE NULL END AS event_id, -- Assuming it's a string ID
    CASE WHEN events.team_id ~ '^[0-9A-Za-z-]+$' THEN events.team_id ELSE NULL END AS team_id,     -- Assuming it's a string ID
    CASE WHEN events.event_time ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_time::TIMESTAMPTZ ELSE NULL END AS event_time,
    CASE WHEN events.event_end ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_end::TIMESTAMPTZ ELSE NULL END AS event_end,
    CASE WHEN events.latitude ~ '^-?\d+(\.\d+)?$' THEN events.latitude::NUMERIC ELSE NULL END AS latitude,
    CASE WHEN events.longitude ~ '^-?\d+(\.\d+)?$' THEN events.longitude::NUMERIC ELSE NULL END AS longitude
FROM
    {{ ref('events') }} AS events
WHERE
    -- Filter out rows with invalid types based on CASE statement output
    (CASE WHEN events.event_id ~ '^[0-9A-Za-z-]+$' THEN events.event_id ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.team_id ~ '^[0-9A-Za-z-]+$' THEN events.team_id ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.event_time ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_time::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.event_end ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN events.event_end::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.latitude ~ '^-?\d+(\.\d+)?$' THEN events.latitude::NUMERIC ELSE NULL END) IS NOT NULL AND
    (CASE WHEN events.longitude ~ '^-?\d+(\.\d+)?$' THEN events.longitude::NUMERIC ELSE NULL END) IS NOT NULL