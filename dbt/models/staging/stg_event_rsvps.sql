-- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,
    responded_at
FROM {{ source('public', 'raw_event_rsvps') }} AS event_rsvps
INNER JOIN {{ ref('stg_events') }} AS events
    ON event_rsvps.event_id = events.event_id
INNER JOIN {{ ref('stg_memberships') }} AS memberships
    ON event_rsvps.membership_id = memberships.membership_id
WHERE rsvp_status IN ('0', '1', '2')