-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    status,
    rsvp_time
FROM {{ source('public', 'raw_event_rsvps') }}
WHERE status IN ('accepted', 'declined', 'pending')