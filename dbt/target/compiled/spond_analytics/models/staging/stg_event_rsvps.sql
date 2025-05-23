-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,
    responded_at
FROM "spond_analytics"."public"."event_rsvps"