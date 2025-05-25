-- tests/assert_daily_active_teams_validity.sql
-- This test checks if:
-- 1. The event_date is never NULL.
-- 2. The distinct_active_teams count is never negative.
-- It will return rows if any of these conditions are violated, causing the dbt test to fail.

SELECT
    event_date,
    distinct_active_teams
FROM
    {{ ref('daily_active_teams') }}
WHERE
    event_date IS NULL
    OR distinct_active_teams < 0
    -- COUNT() typically doesn't return NULL, but adding IS NULL check is defensive.
    OR distinct_active_teams IS NULL