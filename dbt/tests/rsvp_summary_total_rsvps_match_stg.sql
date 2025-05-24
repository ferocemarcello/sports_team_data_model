-- tests/rsvp_summary_total_rsvps_match_stg.sql
-- This test checks if the sum of all RSVP categories in rsvp_summary
-- for a given event_id and rsvp_date equals the total number of raw RSVPs
-- from stg_event_rsvps for the same event_id and date.

WITH summary_counts AS (
    SELECT
        event_id,
        rsvp_date,
        (accepted_rsvps + declined_rsvps + no_response_rsvps) AS total_rsvps_summary
    FROM {{ ref('rsvp_summary') }}
),
staging_counts AS (
    SELECT
        event_id,
        (TO_TIMESTAMP(responded_at / 1000))::DATE AS rsvp_date,
        COUNT(*) AS total_rsvps_stg
    FROM {{ ref('stg_event_rsvps') }}
    WHERE responded_at IS NOT NULL -- Only count records that have a response date
    GROUP BY 1, 2
)
SELECT
    sc.event_id,
    sc.rsvp_date,
    sc.total_rsvps_summary,
    stc.total_rsvps_stg
FROM summary_counts sc
JOIN staging_counts stc
    ON sc.event_id = stc.event_id
    AND sc.rsvp_date = stc.rsvp_date
WHERE sc.total_rsvps_summary != stc.total_rsvps_stg