-- tests/attendance_rate_30_days_is_valid.sql
-- This test checks if the overall_attendance_rate_30_days is within a valid range (0 to 1) and not NULL.
SELECT
    overall_attendance_rate_30_days
FROM {{ ref('attendance_rate_30_days') }}
WHERE
    overall_attendance_rate_30_days IS NULL
    OR overall_attendance_rate_30_days < 0
    OR overall_attendance_rate_30_days > 1