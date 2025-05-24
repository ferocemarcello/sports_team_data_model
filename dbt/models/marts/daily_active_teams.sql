SELECT
    DATE(e.created_at) AS event_date,
    COUNT(DISTINCT e.team_id) AS distinct_active_teams
FROM
    {{ ref('stg_events') }} AS e
WHERE
    e.created_at IS NOT NULL
GROUP BY
    1
ORDER BY
    1;