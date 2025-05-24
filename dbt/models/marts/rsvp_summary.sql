SELECT
    event_id,
    -- Convert BIGINT responded_at (milliseconds) to TIMESTAMP, then extract DATE
    (TO_TIMESTAMP(responded_at / 1000))::DATE AS rsvp_date,
    SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS accepted_rsvps,    -- 1 for accepted
    SUM(CASE WHEN rsvp_status = 2 THEN 1 ELSE 0 END) AS declined_rsvps,    -- 2 for declined
    SUM(CASE WHEN rsvp_status = 0 THEN 1 ELSE 0 END) AS no_response_rsvps  -- 0 for unanswered
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