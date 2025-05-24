-- dbt/models/staging/events.sql
SELECT
    TRY_CAST(event_id AS INT) AS event_id,      -- Keep as VARCHAR if it's a string ID
    TRY_CAST(team_id AS INT) AS team_id,        -- Keep as VARCHAR if it's a string ID
    TRY_CAST(event_time AS TIMESTAMPTZ) AS event_time,
    TRY_CAST(event_end AS TIMESTAMPTZ) AS event_end,
    TRY_CAST(latitude AS NUMERIC) AS latitude,
    TRY_CAST(longitude AS NUMERIC) AS longitude
FROM
    {{ ref('events') }}
WHERE
    -- Filter out rows with invalid types
    TRY_CAST(event_id AS INT) IS NOT NULL AND
    TRY_CAST(team_id AS INT) IS NOT NULL AND
    TRY_CAST(event_time AS TIMESTAMPTZ) IS NOT NULL AND
    TRY_CAST(event_end AS TIMESTAMPTZ) IS NOT NULL AND
    TRY_CAST(latitude AS NUMERIC) IS NOT NULL AND
    TRY_CAST(longitude AS NUMERIC) IS NOT NULL