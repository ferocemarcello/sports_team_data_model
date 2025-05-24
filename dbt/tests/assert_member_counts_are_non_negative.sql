-- tests/assert_member_counts_are_non_negative.sql
-- This test checks if:
-- 1. The week_start_date is never NULL.
-- 2. The new_event_participants_this_week count is never negative.
-- 3. The returning_event_participants_this_week count is never negative.

SELECT
    week_start_date,
    new_event_participants_this_week,
    returning_event_participants_this_week
FROM
    {{ ref('new_vs_returning_members') }}
WHERE
    week_start_date IS NULL -- Ensure the date column is not null
    OR new_event_participants_this_week < 0 -- Check for negative new participant counts
    OR new_event_participants_this_week IS NULL -- COUNT() doesn't return NULL, but good defensive check
    OR returning_event_participants_this_week < 0 -- Check for negative returning participant counts
    OR returning_event_participants_this_week IS NULL -- COUNT() doesn't return NULL, but good defensive check