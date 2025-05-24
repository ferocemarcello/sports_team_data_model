WITH recent_rsvps AS (
    SELECT
        rsvp_status
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        -- Filter for records responded/recorded within the last 30 days
        responded_at >= CURRENT_DATE - INTERVAL '30 days'
        AND responded_at IS NOT NULL -- Ensure we only count records with a response date
)
SELECT
    -- Calculate the overall attendance rate as (total accepted / total responses)
    CAST(SUM(CASE WHEN rsvp_status = 'accepted' THEN 1 ELSE 0 END) AS DECIMAL) /
    NULLIF(COUNT(*), 0) AS overall_attendance_rate_30_days
FROM
    recent_rsvps;