-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    rsvp_id,         -- Selects the column as it is named in the raw table
    event_id,
    membership_id,
    status,          -- Selects the column as it is named in the raw table
    rsvp_time        -- Selects the column as it is named in the raw table
FROM "spond_analytics"."public"."event_rsvps"
WHERE status IN ('accepted', 'declined', 'pending') -- Corrected filter to use 'status'