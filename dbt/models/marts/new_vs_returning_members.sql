-- models/marts/new_vs_returning_members.sql
-- Calculates new vs. returning members based on event RSVP activity,
-- where 'membership_id' serves as the unique identifier for each individual.

WITH event_participations_with_membership_id AS (
    SELECT
        ser.membership_id, -- Use membership_id here, as it indicates a single individual
        (TO_TIMESTAMP(ser.responded_at)) AS responded_at_timestamp -- Use correct timestamp conversion
    FROM
        {{ ref('stg_event_rsvps') }} AS ser
    WHERE
        ser.responded_at IS NOT NULL
    -- No join to stg_memberships needed in this CTE, as membership_id is in stg_event_rsvps directly for this calculation.
),
membership_first_event_participation AS (
    SELECT
        membership_id,
        MIN(responded_at_timestamp) AS first_participation_timestamp
    FROM
        event_participations_with_membership_id
    GROUP BY
        membership_id -- Group by membership_id
),
weekly_active_event_memberships AS (
    SELECT
        DATE_TRUNC('week', responded_at_timestamp) AS week_start_date,
        membership_id
    FROM
        event_participations_with_membership_id
    GROUP BY
        1, 2
),
all_relevant_weeks AS (
    SELECT week_start_date
    FROM GENERATE_SERIES(
        DATE_TRUNC('week', (SELECT MIN(first_participation_timestamp) FROM membership_first_event_participation)),
        DATE_TRUNC('week', CURRENT_DATE),
        '1 week'::interval
    ) AS s(week_start_date)
)
SELECT
    arw.week_start_date,
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('week', mfep.first_participation_timestamp) = arw.week_start_date
        THEN mfep.membership_id -- Count distinct membership_id for new members
    END) AS new_event_participants_this_week, -- Renamed for clarity to reflect individual participation
    COUNT(DISTINCT CASE
        WHEN waem.week_start_date = arw.week_start_date
        AND DATE_TRUNC('week', mfep.first_participation_timestamp) < arw.week_start_date
        THEN waem.membership_id -- Count distinct membership_id for returning members
    END) AS returning_event_participants_this_week -- Renamed for clarity to reflect individual participation
FROM
    all_relevant_weeks AS arw
LEFT JOIN
    weekly_active_event_memberships AS waem
    ON waem.week_start_date = arw.week_start_date
LEFT JOIN
    membership_first_event_participation AS mfep
    ON waem.membership_id = mfep.membership_id
GROUP BY
    arw.week_start_date
ORDER BY
    arw.week_start_date