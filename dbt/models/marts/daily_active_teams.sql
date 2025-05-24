-- models/marts/daily_active_teams.sql
-- How many distinct teams hosted or had events created each day?

WITH team_event_activities AS (
    -- Activity based on event start date
    SELECT
        team_id,
        (TO_TIMESTAMP(event_start / 1000))::DATE AS activity_date
    FROM {{ ref('stg_events') }}
    WHERE event_start IS NOT NULL

    UNION ALL

    -- Activity based on event creation date
    -- This captures "updated" if an event's creation is considered an update/activity
    SELECT
        team_id,
        (TO_TIMESTAMP(created_at / 1000))::DATE AS activity_date
    FROM {{ ref('stg_events') }}
    WHERE created_at IS NOT NULL
)
SELECT
    activity_date AS event_date,
    COUNT(DISTINCT team_id) AS distinct_active_teams
FROM team_event_activities
WHERE activity_date IS NOT NULL -- Ensure the derived date is not null
GROUP BY 1
ORDER BY 1