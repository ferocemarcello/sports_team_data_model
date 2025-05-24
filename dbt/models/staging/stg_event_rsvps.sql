-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvps.event_rsvp_id,
    event_rsvps.event_id,
    event_rsvps.membership_id,
    event_rsvps.rsvp_status,
    -- Use CASE for robust type casting for responded_at
    CASE WHEN event_rsvps.responded_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN event_rsvps.responded_at::TIMESTAMPTZ ELSE NULL END AS rsvp_time
FROM
    {{ ref('event_rsvps') }} AS event_rsvps
WHERE
    event_rsvps.rsvp_status IN ('0', '1', '2') AND
    (CASE WHEN event_rsvps.responded_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN event_rsvps.responded_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL