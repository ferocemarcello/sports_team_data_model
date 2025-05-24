-- dbt/models/staging/teams.sql
SELECT
    -- Safely cast team_id to INT. If it doesn't consist solely of digits, it becomes NULL.
    CASE
        WHEN teams.team_id ~ '^[0-9]+$' THEN teams.team_id::INT
        ELSE NULL
    END AS team_id,
    teams.team_activity,
    teams.country_code,
    -- Safely convert created_at to epoch seconds since 1970-01-01 00:00:00 UTC
    CASE
        WHEN teams.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$'
        THEN EXTRACT(EPOCH FROM (teams.created_at::TIMESTAMPTZ))::BIGINT -- <--- CHANGED
        ELSE NULL
    END AS created_at
FROM
    {{ ref('teams') }} AS teams
INNER JOIN {{ ref('country_codes') }} AS valid_country_codes
    ON teams.country_code = valid_country_codes.alpha_three
WHERE
    -- Filter out rows where team_id was not a valid INT (i.e., became NULL after the CASE statement)
    (CASE WHEN teams.team_id ~ '^[0-9]+$' THEN teams.team_id::INT ELSE NULL END) IS NOT NULL
    -- Filter out rows where created_at was not a valid TIMESTAMPTZ (i.e., became NULL after the CASE statement)
    AND (CASE WHEN teams.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN teams.created_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL
    -- Ensure country_code is not null after the join (this is often redundant with INNER JOIN but good for clarity).
    AND teams.country_code IS NOT NULL