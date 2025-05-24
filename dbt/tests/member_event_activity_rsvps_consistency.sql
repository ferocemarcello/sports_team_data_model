-- tests/member_event_activity_rsvps_consistency.sql
-- This test ensures that a member's accepted and declined RSVPs don't exceed their total RSVPs made,
-- and all counts are non-negative.
SELECT
    membership_id,
    total_rsvps_made,
    total_accepted_rsvps,
    total_declined_rsvps
FROM {{ ref('rsvp_summary') }}
WHERE
    total_rsvps_made < 0
    OR total_accepted_rsvps < 0
    OR total_declined_rsvps < 0
    OR (total_accepted_rsvps + total_declined_rsvps) > total_rsvps_made -- Simple check if sum exceeds total