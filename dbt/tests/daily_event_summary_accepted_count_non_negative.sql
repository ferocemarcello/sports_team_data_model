-- tests/daily_event_summary_accepted_count_non_negative.sql
-- This test ensures that the count of accepted attendees is never negative.
SELECT
    event_id,
    event_date,
    total_accepted_attendees
FROM {{ ref('daily_event_summary') }} -- Adjust 'daily_event_summary' to your actual view name
WHERE total_accepted_attendees < 0