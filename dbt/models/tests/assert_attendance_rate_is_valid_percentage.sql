-- tests/assert_attendance_rate_is_valid_percentage.sql
-- This test checks if the overall attendance rate is between 0 and 100 (inclusive).
-- It will return rows if the condition is violated, causing the dbt test to fail.

SELECT
    overall_attendance_rate_percentage_last_30_days
FROM
    {{ ref('attendance_rate_30_days') }}
WHERE
    overall_attendance_rate_percentage_last_30_days < 0
    OR overall_attendance_rate_percentage_last_30_days > 100
    -- Although COALESCE(..., 0) should prevent NULL, this adds a safeguard.
    OR overall_attendance_rate_percentage_last_30_days IS NULL