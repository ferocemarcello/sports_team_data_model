SELECT
    event_rsvps.event_rsvp_id AS event_rsvp_id,
    event_rsvps.event_id AS event_id,
    event_rsvps.membership_id AS membership_id,
    event_rsvps.rsvp_status,
    EXTRACT(EPOCH FROM event_rsvps.responded_at)::BIGINT AS responded_at
FROM
    {{ ref('event_rsvps') }} AS event_rsvps
INNER JOIN {{ ref('stg_events') }} AS events
    ON event_rsvps.event_id = events.event_id
INNER JOIN {{ ref('stg_memberships') }} AS memberships
    ON event_rsvps.membership_id = memberships.membership_id
WHERE
    event_rsvps.rsvp_status IN ('0', '1', '2') AND
    event_rsvps.event_rsvp_id IS NOT NULL AND
    event_rsvps.event_id IS NOT NULL AND
    event_rsvps.membership_id IS NOT NULL