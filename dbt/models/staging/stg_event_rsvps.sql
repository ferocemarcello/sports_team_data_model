SELECT
    -- Cast IDs to INT, filtering out non-numeric values
    CASE WHEN event_rsvps.event_rsvp_id ~ '^[0-9]+$' THEN event_rsvps.event_rsvp_id::INT ELSE NULL END AS event_rsvp_id,
    CASE WHEN event_rsvps.event_id ~ '^[0-9]+$' THEN event_rsvps.event_id::INT ELSE NULL END AS event_id,
    CASE WHEN event_rsvps.membership_id ~ '^[0-9]+$' THEN event_rsvps.membership_id::INT ELSE NULL END AS membership_id,
    event_rsvps.rsvp_status,
    -- Use CASE for robust type casting for responded_at
    CASE WHEN event_rsvps.responded_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN event_rsvps.responded_at::TIMESTAMPTZ ELSE NULL END AS rsvp_time
FROM
    {{ ref('event_rsvps') }} AS event_rsvps
INNER JOIN {{ ref('stg_events') }} AS events -- Join to the STAGING events model
    ON (CASE WHEN event_rsvps.event_id ~ '^[0-9]+$' THEN event_rsvps.event_id::INT ELSE NULL END) = events.event_id
INNER JOIN {{ ref('stg_memberships') }} AS memberships -- Join to the STAGING memberships model
    ON (CASE WHEN event_rsvps.membership_id ~ '^[0-9]+$' THEN event_rsvps.membership_id::INT ELSE NULL END) = memberships.membership_id
WHERE
    event_rsvps.rsvp_status IN ('0', '1', '2') AND
    (CASE WHEN event_rsvps.responded_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN event_rsvps.responded_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL AND
    -- Filter out rows where IDs are not valid INTs before joining
    (CASE WHEN event_rsvps.event_rsvp_id ~ '^[0-9]+$' THEN event_rsvps.event_rsvp_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN event_rsvps.event_id ~ '^[0-9]+$' THEN event_rsvps.event_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN event_rsvps.membership_id ~ '^[0-9]+$' THEN event_rsvps.membership_id::INT ELSE NULL END) IS NOT NULL