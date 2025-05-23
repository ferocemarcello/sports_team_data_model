-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id AS rsvp_id,
    event_id,
    membership_id,
    rsvp_status AS status,
    responded_at AS rsvp_time
FROM "spond_analytics"."public"."raw_event_rsvps"
WHERE rsvp_status IN ('accepted', 'declined', 'pending') -- Keep this filter