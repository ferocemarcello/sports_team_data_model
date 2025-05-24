-- models/marts/new_vs_returning_members.sql
-- How many new members joined each week, and how many were returning (already joined in a previous week)?
-- Calculates new vs. returning members based on event RSVP activity

WITH event_participations AS (
    SELECT
        ser.membership_id,
        (TO_TIMESTAMP(ser.responded_at)) AS responded_at_timestamp -- Use correct timestamp conversion
    FROM
        {{ ref('stg_event_rsvps') }} AS ser
    WHERE
        ser.responded_at IS NOT NULL
),
membership_first_event_participation AS (
    SELECT
        membership_id,
        MIN(responded_at_timestamp) AS first_participation_timestamp
    FROM
        event_participations
    GROUP BY
        membership_id
),
weekly_active_event_memberships AS (
    SELECT
        DATE_TRUNC('week', responded_at_timestamp) AS week_start_date,
        membership_id
    FROM
        event_participations
    GROUP BY
        week_start_date, membership_id
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
    END) AS new_event_participants_this_week,
    COUNT(DISTINCT CASE
        WHEN waem.week_start_date = arw.week_start_date
        AND DATE_TRUNC('week', mfep.first_participation_timestamp) < arw.week_start_date
        THEN waem.membership_id -- Count distinct membership_id for returning members
    END) AS returning_event_participants_this_week
FROM
    all_relevant_weeks AS arw
LEFT JOIN -- LEFT JOIN so to consider all weeks, even those with no joiners
    weekly_active_event_memberships AS waem
    ON waem.week_start_date = arw.week_start_date
LEFT JOIN
    membership_first_event_participation AS mfep
    ON waem.membership_id = mfep.membership_id
GROUP BY
    arw.week_start_date
ORDER BY
    arw.week_start_date