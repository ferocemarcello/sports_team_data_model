SELECT
    rsvps.id AS rsvp_id,
    rsvps.event_id,
    rsvps.member_id,
    rsvps.rsvp_status AS status,
    rsvps.rsvp_time
FROM {{ source('public', 'raw_event_rsvps') }} AS rsvps
INNER JOIN {{ source('public', 'raw_events') }} AS events -- Ensures event_id exists in raw_events
  ON rsvps.event_id = events.event_id -- CORRECTED: changed to events.event_id
WHERE rsvps.rsvp_status IN ('accepted', 'declined', 'pending') -- Filters for accepted status values