WITH event_participations_with_member_id AS (
    SELECT
        sm.membership_id,
        (TO_TIMESTAMP(ser.responded_at / 1000)) AS responded_at_timestamp -- Convert BIGINT to TIMESTAMP
    FROM
        {{ ref('stg_event_rsvps') }} AS ser
    JOIN
        {{ ref('stg_memberships') }} AS sm
        ON ser.membership_id = sm.membership_id
    WHERE
        ser.responded_at IS NOT NULL -- Only consider actual responses/participations
),
member_first_event_participation AS (
    -- Find the earliest event participation date for each UNIQUE member_id
    SELECT
        membership_id,
        MIN(responded_at_timestamp) AS first_participation_timestamp
    FROM
        event_participations_with_member_id
    GROUP BY
        membership_id
),
weekly_active_event_members AS (
    -- Get all distinct members who participated in an event in each week
    SELECT
        DATE_TRUNC('week', responded_at_timestamp) AS week_start_date,
        membership_id
    FROM
        event_participations_with_member_id
    GROUP BY
        1, 2
),
all_relevant_weeks AS (
    -- Generate a series of weeks from the earliest event participation to the current week
    SELECT week_start_date
    FROM GENERATE_SERIES(
        DATE_TRUNC('week', (SELECT MIN(first_participation_timestamp) FROM member_first_event_participation)),
        DATE_TRUNC('week', CURRENT_DATE),
        '1 week'::interval
    ) AS s(week_start_date)
)
SELECT
    arw.week_start_date,
    -- Count of new event participants for this week:
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('week', mfep.first_participation_timestamp) = arw.week_start_date
        THEN mfep.membership_id
    END) AS new_event_participants_this_week,

    -- Count of returning event participants for this week:
    COUNT(DISTINCT CASE
        WHEN waem.week_start_date = arw.week_start_date -- Active in an event this week
        AND DATE_TRUNC('week', mfep.first_participation_timestamp) < arw.week_start_date -- And their first participation was *before* this week
        THEN waem.membership_id
    END) AS returning_event_participants_this_week
FROM
    all_relevant_weeks AS arw
LEFT JOIN
    weekly_active_event_members AS waem
    ON waem.week_start_date = arw.week_start_date
LEFT JOIN
    member_first_event_participation AS mfep
    ON waem.membership_id = mfep.membership_id
GROUP BY
    arw.week_start_date
ORDER BY
    arw.week_start_date