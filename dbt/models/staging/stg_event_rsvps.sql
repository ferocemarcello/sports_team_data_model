SELECT
    rsvps.event_rsvp_id AS rsvp_id,
    rsvps.event_id,
    rsvps.membership_id, -- Corrected: from member_id to membership_id
    rsvps.rsvp_status AS status,
    rsvps.responded_at AS rsvp_time -- Corrected: from rsvp_time to responded_at
FROM {{ source('public', 'raw_event_rsvps') }} AS rsvps
INNER JOIN {{ source('public', 'raw_events') }} AS events
  ON rsvps.event_id = events.event_id
WHERE rsvps.rsvp_status IN ('accepted', 'declined', 'pending')