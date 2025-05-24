-- dbt/models/staging/event_rsvps.sql
SELECT
    event_rsvps.event_rsvp_id,
    event_rsvps.event_id,
    event_rsvps.membership_id,
    event_rsvps.rsvp_status,
    TRY_CAST(event_rsvps.responded_at AS TIMESTAMPTZ) AS rsvp_time -- Cast to TIMESTAMPTZ
FROM
    {{ ref('event_rsvps') }} AS event_rsvps -- <--- CHANGED FROM {{ source('public', 'raw_event_rsvps') }}
INNER JOIN {{ ref('events') }} AS events -- Join to ensure event_id exists in events (now a seed)
    ON event_rsvps.event_id = events.event_id
INNER JOIN {{ ref('memberships') }} AS memberships -- Join to ensure membership_id exists in memberships (now a seed)
    ON event_rsvps.membership_id = memberships.membership_id
WHERE
    event_rsvps.rsvp_status IN ('0', '1', '2') AND
    TRY_CAST(event_rsvps.responded_at AS TIMESTAMPTZ) IS NOT NULL