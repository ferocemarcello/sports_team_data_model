WITH event_participations_with_member_id AS (
    SELECT
        sm.member_id,
        (TO_TIMESTAMP(ser.responded_at)) AS responded_at_timestamp -- REMOVED / 1000
    FROM
        {{ ref('stg_event_rsvps') }} AS ser
    JOIN
        {{ ref('stg_memberships') }} AS sm
        ON ser.membership_id = sm.membership_id
    WHERE
        ser.responded_at IS NOT NULL
),
member_first_event_participation AS (
    SELECT
        member_id,
        MIN(responded_at_timestamp) AS first_participation_timestamp
    FROM
        event_participations_with_member_id
    GROUP BY
        member_id
),
weekly_active_event_members AS (
    SELECT
        DATE_TRUNC('week', responded_at_timestamp) AS week_start_date,
        member_id
    FROM
        event_participations_with_member_id
    GROUP BY
        1, 2
),
all_relevant_weeks AS (
    SELECT week_start_date
    FROM GENERATE_SERIES(
        DATE_TRUNC('week', (SELECT MIN(first_participation_timestamp) FROM member_first_event_participation)),
        DATE_TRUNC('week', CURRENT_DATE),
        '1 week'::interval
    ) AS s(week_start_date)
)
SELECT
    arw.week_start_date,
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('week', mfep.first_participation_timestamp) = arw.week_start_date
        THEN mfep.member_id
    END) AS new_event_participants_this_week,
    COUNT(DISTINCT CASE
        WHEN waem.week_start_date = arw.week_start_date
        AND DATE_TRUNC('week', mfep.first_participation_timestamp) < arw.week_start_date
        THEN waem.member_id
    END) AS returning_event_participants_this_week
FROM
    all_relevant_weeks AS arw
LEFT JOIN
    weekly_active_event_members AS waem
    ON waem.week_start_date = arw.week_start_date
LEFT JOIN
    member_first_event_participation AS mfep
    ON waem.member_id = mfep.member_id
GROUP BY
    arw.week_start_date
ORDER BY
    arw.week_start_date;