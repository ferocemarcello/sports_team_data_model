SELECT
    t.country_code, -- Get country code from the hosting team
    COUNT(e.event_id) AS events_hosted
FROM
    {{ ref('stg_events') }} AS e
JOIN
    {{ ref('stg_teams') }} AS t
    ON e.team_id = t.team_id
WHERE
    t.country_code IS NOT NULL
GROUP BY
    t.country_code
ORDER BY
    t.country_code