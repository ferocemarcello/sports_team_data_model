-- models/marts/attendance_rate_30_days.sql
-- (Note: The model name 'attendance_rate_30_days' might be misleading if the
--  data window is not exactly the last 30 days from CURRENT_DATE.
--  Consider renaming this model to e.g., 'overall_attendance_rate_2024'
--  to reflect the actual data period being analyzed.)

WITH rsvps_in_data_range AS (
    SELECT
        rsvp_status,
        (TO_TIMESTAMP(responded_at)) AS responded_at_timestamp
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        -- Filter for all records from 2024, based on your data range
        (TO_TIMESTAMP(responded_at))::DATE >= DATE '2024-01-01'
        AND (TO_TIMESTAMP(responded_at))::DATE <= DATE '2024-12-31'
        AND responded_at IS NOT NULL
)
SELECT
    CAST(SUM(CASE WHEN rsvp_status = 1 THEN 1 ELSE 0 END) AS DECIMAL) /
    NULLIF(COUNT(*), 0) AS overall_attendance_rate_for_data_period -- Renamed output column for clarity
FROM
    rsvps_in_data_range