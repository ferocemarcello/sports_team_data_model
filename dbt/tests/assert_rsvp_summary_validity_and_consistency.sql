-- tests/assert_rsvp_summary_validity_and_consistency.sql
-- This test checks for data quality and logical consistency in the rsvp_summary model:
-- 1. event_id and rsvp_date are not NULL.
-- 2. All RSVP counts (accepted, declined, no_response) are non-negative.
-- 3. The sum of accepted, declined, and no_response RSVPs for an event on a date
--    matches the actual total number of RSVPs for that event on that date from raw data.

SELECT
    s.event_id,
    s.rsvp_date,
    s.accepted_rsvps,
    s.declined_rsvps,
    s.no_response_rsvps,
    raw_totals.actual_total_rsvps AS expected_total,
    (s.accepted_rsvps + s.declined_rsvps + s.no_response_rsvps) AS calculated_total
FROM
    {{ ref('rsvp_summary') }} AS s
LEFT JOIN (
    -- Subquery to calculate the actual total RSVPs per event_id, rsvp_date from raw data
    SELECT
        event_id,
        (TO_TIMESTAMP(responded_at))::DATE AS rsvp_date,
        COUNT(*) AS actual_total_rsvps
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        responded_at IS NOT NULL
    GROUP BY
        event_id,
        (TO_TIMESTAMP(responded_at))::DATE
) AS raw_totals
ON s.event_id = raw_totals.event_id AND s.rsvp_date = raw_totals.rsvp_date
WHERE
    -- Check for NULL primary keys
    s.event_id IS NULL
    OR s.rsvp_date IS NULL
    -- Check for negative or NULL counts (COUNT() functions should not be NULL, but defensive)
    OR s.accepted_rsvps < 0 OR s.accepted_rsvps IS NULL
    OR s.declined_rsvps < 0 OR s.declined_rsvps IS NULL
    OR s.no_response_rsvps < 0 OR s.no_response_rsvps IS NULL
    -- Check for consistency: sum of parts should equal total from raw data
    OR (s.accepted_rsvps + s.declined_rsvps + s.no_response_rsvps) != raw_totals.actual_total_rsvps
    -- Also check if there are summary rows that don't have a corresponding raw total (shouldn't happen with LEFT JOIN)
    OR raw_totals.actual_total_rsvps IS NULL