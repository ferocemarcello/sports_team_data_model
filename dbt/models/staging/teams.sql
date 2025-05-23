SELECT
    team_id,
    team_activity,
    country_code,
    created_at
FROM
    {{ source('public', 'raw_teams') }} as teams
INNER JOIN {{ ref('country_codes') }} AS country_codes
    ON teams.country_code = country_codes.alpha_three