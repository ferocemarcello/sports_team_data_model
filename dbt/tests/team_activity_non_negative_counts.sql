-- tests/team_activity_non_negative_counts.sql
-- This test ensures that various counts related to team activity are non-negative.
SELECT
    team_id,
    total_events_participated,
    total_members_attending
FROM {{ ref('team_activity') }} -- Adjust 'team_activity' to your actual view name
WHERE
    total_events_participated < 0
    OR total_members_attending < 0