-- models/marts/attendance_rate_30_days.sql
-- Calculates overall attendance rate for the data period (e.g., 2024)
-- and expresses it as a percentage (0-100 scale).

WITH rsvps_in_data_range AS (
    SELECT
        rsvp_status,
        (TO_TIMESTAMP(responded_at)) AS responded_at_timestamp
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        (TO_TIMESTAMP(responded_at))::DATE >= DATE '2024-01-01'
        AND (TO_TIMESTAMP(responded_at))::DATE <= DATE '2024-12-31'
        AND responded_at IS NOT NULL
)
SELECT
    ROUND( -- Round the final percentage value
        (
            CAST(SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS DECIMAL) /
            NULLIF(COUNT(*), 0)
        ) * 100, -- Multiply by 100 to convert to percentage
        2 -- Round to 2 decimal places (e.g., 48.37)
    ) AS overall_attendance_rate_percentage -- Renamed column to reflect percentage
FROM
    rsvps_in_data_range