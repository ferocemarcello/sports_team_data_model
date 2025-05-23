-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,   -- Keep the original raw column name
    responded_at   -- Keep the original raw column name
FROM {{ source('public', 'event_rsvps') }}
WHERE rsvp_status IN ('accepted', 'declined', 'pending')