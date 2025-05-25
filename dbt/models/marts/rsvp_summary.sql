-- For each event, indicate how many members responded as accepted, 
-- how many responded as declined, and how many did not respond at any given day.


SELECT
    event_id,
    -- Convert BIGINT responded_at (seconds) to TIMESTAMP, then extract DATE
    (TO_TIMESTAMP(responded_at))::DATE AS rsvp_date,
    SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS accepted_rsvps,
    SUM(CASE WHEN rsvp_status = 2 THEN 1 ELSE 0 END) AS declined_rsvps,
    SUM(CASE WHEN rsvp_status = 0 THEN 1 ELSE 0 END) AS no_response_rsvps
FROM
    {{ ref('stg_event_rsvps') }}
WHERE
    responded_at IS NOT NULL
GROUP BY
    event_id,
    rsvp_date
ORDER BY
    event_id,
    rsvp_date