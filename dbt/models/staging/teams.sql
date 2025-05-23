SELECT
    team_id,
    team_activity,
    country_code,
    created_at
FROM
    {{ source('public', 'raw_teams') }}