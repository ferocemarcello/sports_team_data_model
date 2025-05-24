SELECT
    teams.team_id AS team_id,
    teams.team_activity AS team_activity,
    teams.country_code AS country_code,
    EXTRACT(EPOCH FROM teams.created_at)::BIGINT AS created_at
FROM
    {{ ref('teams') }} AS teams
INNER JOIN {{ ref('country_codes') }} AS valid_country_codes
    ON teams.country_code = valid_country_codes.alpha_three
WHERE
    teams.team_id IS NOT NULL