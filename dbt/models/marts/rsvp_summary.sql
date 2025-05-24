SELECT
    event_id,
    -- Convert BIGINT responded_at (milliseconds) to TIMESTAMP, then extract DATE
    (TO_TIMESTAMP(responded_at / 1000))::DATE AS rsvp_date,
    SUM(CASE WHEN rsvp_status = 'accepted' THEN 1 ELSE 0 END) AS accepted_rsvps,
    SUM(CASE WHEN rsvp_status = 'declined' THEN 1 ELSE 0 END) AS declined_rsvps,
    -- Count records where status is NULL or not 'accepted'/'declined' as no response.
    -- Note: These counts will only appear on a 'rsvp_date' if responded_at is NOT NULL for them.
    SUM(CASE WHEN rsvp_status IS NULL OR (rsvp_status <> 'accepted' AND rsvp_status <> 'declined') THEN 1 ELSE 0 END) AS no_response_rsvps
FROM
    {{ ref('stg_event_rsvps') }}
WHERE
    responded_at IS NOT NULL -- Only group by actual response dates
GROUP BY
    event_id,
    rsvp_date
ORDER BY
    event_id,
    rsvp_date