-- models/marts/daily_active_teams.sql
-- How many distinct teams hosted or had events created each day?

WITH team_event_activities AS (
    -- Activity based on event start date
    SELECT
        team_id,
        (TO_TIMESTAMP(event_start))::DATE AS activity_date -- REMOVED / 1000
    FROM {{ ref('stg_events') }}
    WHERE event_start IS NOT NULL

    UNION ALL

    -- Activity based on event creation date
    SELECT
        team_id,
        (TO_TIMESTAMP(created_at))::DATE AS activity_date -- REMOVED / 1000
    FROM {{ ref('stg_events') }}
    WHERE created_at IS NOT NULL
)
SELECT
    activity_date AS event_date,
    COUNT(DISTINCT team_id) AS distinct_active_teams
FROM team_event_activities
WHERE activity_date IS NOT NULL
GROUP BY 1
ORDER BY 1