-- models/marts/attendance_rate_30_days.sql
-- Over the last 30 days, what’s the average percentage of “Accepted” RSVPs compared to total invites sent?
-- Returns zero rows if there are no RSVPs in the last 30 days.

WITH rsvps_in_data_range AS (
    SELECT
        rsvp_status,
        (TO_TIMESTAMP(responded_at)) AS responded_at_timestamp
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        responded_at IS NOT NULL AND
        responded_at >= (EXTRACT(EPOCH FROM CURRENT_DATE)::BIGINT - 2592000) -- 30 days in seconds
        AND responded_at < EXTRACT(EPOCH FROM (CURRENT_DATE + INTERVAL '1 day'))::BIGINT -- Taking the whole current date
),
calculated_rate AS (
    SELECT
        ROUND(
            (
                CAST(SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS DECIMAL) /
                NULLIF(COUNT(*), 0)
            ) * 100,
            2
        ) AS overall_attendance_rate_percentage_last_30_days
    FROM
        rsvps_in_data_range
)
SELECT
    overall_attendance_rate_percentage_last_30_days
FROM
    calculated_rate
WHERE
    overall_attendance_rate_percentage_last_30_days IS NOT NULL