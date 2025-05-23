SELECT
    team_id,
    team_activity,
    country_code,
    created_at
FROM
    {{ source('public', 'raw_teams') }} as teams
INNER JOIN {{ ref('country_codes') }} AS country_codes
    ON teams.country_code = country_codes.alpha_three
WHERE
-- Only include rows where team_id successfully cast to INT
TRY_CAST(teams.team_id AS INT) IS NOT NULL
-- Only include rows where created_at successfully cast to TIMESTAMPTZ
AND TRY_CAST(teams.created_at AS TIMESTAMPTZ) IS NOT NULL
-- Ensure country_code is not null after the join (though INNER JOIN implies this)
AND teams.country_code IS NOT NULL