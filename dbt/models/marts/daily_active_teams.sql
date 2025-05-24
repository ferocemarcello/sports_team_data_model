-- models/marts/daily_active_teams.sql (or wherever this view is defined)

SELECT
    (TO_TIMESTAMP(se.event_start / 1000))::DATE AS event_date, -- <-- Fix is here
    COUNT(DISTINCT sm.team_id) AS distinct_active_teams
FROM {{ ref('stg_events') }} se
JOIN {{ ref('stg_memberships') }} sm -- Assuming you join to get team_id
  ON se.host_member_id = sm.membership_id -- Or whatever your join condition is
WHERE se.event_start IS NOT NULL -- Exclude null timestamps
GROUP BY 1
ORDER BY 1;