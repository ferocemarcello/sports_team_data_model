-- tests/assert_events_hosted_non_negative.sql
-- This test checks if:
-- 1. The 'events_hosted' count is never negative.
-- 2. The 'country_code' is not NULL.
-- 3. The 'country_code' is a string of exactly 3 uppercase letters (e.g., 'NOR', 'USA').
-- 4. The 'country_code' does NOT consist of the same letter repeated three times (e.g., not 'AAA', 'BBB').

SELECT
    country_code,
    events_hosted
FROM
    {{ ref('events_per_region') }}
WHERE
    events_hosted < 0
    OR events_hosted IS NULL
    -- Checks for country_code format:
    OR country_code IS NULL
    OR country_code !~ '^[A-Z]{3}$' -- Ensures it's exactly 3 uppercase letters
    OR country_code ~ '(.)\1\1' -- This pattern matches if the same character repeats 3 times.