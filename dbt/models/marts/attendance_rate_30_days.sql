WITH recent_rsvps AS (
    SELECT
        rsvp_status,
        -- Convert BIGINT responded_at (seconds) to TIMESTAMP for comparison
        (TO_TIMESTAMP(responded_at)) AS responded_at_timestamp -- REMOVED / 1000
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        -- Filter for records responded/recorded within the last 30 days
        -- Compare TIMESTAMP with TIMESTAMP
        (TO_TIMESTAMP(responded_at)) >= CURRENT_DATE - INTERVAL '30 days' -- REMOVED / 1000
        AND responded_at IS NOT NULL
)
SELECT
    CAST(SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS DECIMAL) /
    NULLIF(COUNT(*), 0) AS overall_attendance_rate_30_days
FROM
    recent_rsvps