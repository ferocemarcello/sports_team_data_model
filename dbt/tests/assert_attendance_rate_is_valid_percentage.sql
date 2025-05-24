-- tests/assert_attendance_rate_is_valid_percentage.sql
-- This test checks if the overall attendance rate (if present) is between 0 and 100 (inclusive).
-- The model it references returns zero rows if there is no attendance data.
-- This test will return rows (and fail) only if the percentage is out of range.

SELECT
    overall_attendance_rate_percentage_last_30_days
FROM
    {{ ref('attendance_rate_30_days') }}
WHERE
    overall_attendance_rate_percentage_last_30_days < 0
    OR overall_attendance_rate_percentage_last_30_days > 100