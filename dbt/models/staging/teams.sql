SELECT
    -- Attempt to cast team_id to INT. If it fails (e.g., 'abc'), it becomes NULL.
    TRY_CAST(teams.team_id AS INT) AS team_id,
    teams.team_activity,
    teams.country_code,
    -- Attempt to cast created_at to TIMESTAMPTZ (handles ISO 8601 format like '...Z').
    -- If it fails, it becomes NULL.
    TRY_CAST(teams.created_at AS TIMESTAMPTZ) AS created_at
FROM
    {{ source('public', 'raw_teams') }} AS teams
INNER JOIN {{ ref('country_codes') }} AS valid_country_codes
    -- IMPORTANT: Use double quotes for 'alpha-3' because of the hyphen in the column name from your CSV
    ON teams.country_code = valid_country_codes."alpha-3"
WHERE
    -- Only include rows where team_id successfully cast to INT (i.e., not NULL after TRY_CAST)
    TRY_CAST(teams.team_id AS INT) IS NOT NULL
    -- Only include rows where created_at successfully cast to TIMESTAMPTZ
    AND TRY_CAST(teams.created_at AS TIMESTAMPTZ) IS NOT NULL
    -- Ensure country_code is not null after the join.
    AND teams.country_code IS NOT NULL