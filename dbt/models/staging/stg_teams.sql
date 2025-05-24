-- dbt/models/staging/teams.sql
SELECT
    -- Safely cast team_id to INT. If it doesn't consist solely of digits, it becomes NULL.
    CASE
        WHEN teams.team_id ~ '^[0-9]+$' THEN teams.team_id::INT
        ELSE NULL
    END AS team_id,
    teams.team_activity,
    teams.country_code,
    EXTRACT(EPOCH FROM teams.created_at)::BIGINT AS created_at
FROM
    {{ ref('teams') }} AS teams
INNER JOIN {{ ref('country_codes') }} AS valid_country_codes
    ON teams.country_code = valid_country_codes.alpha_three
WHERE
    -- Filter out rows where team_id was not a valid INT (i.e., became NULL after the CASE statement)
    (CASE WHEN teams.team_id ~ '^[0-9]+$' THEN teams.team_id::INT ELSE NULL END) IS NOT NULL
    -- Filter out rows where created_at was not a valid TIMESTAMPTZ (i.e., became NULL after the CASE statement)
    AND teams.created_at IS NOT NULL
    AND teams.country_code IS NOT NULL