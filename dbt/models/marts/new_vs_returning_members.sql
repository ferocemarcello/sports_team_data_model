WITH member_first_event_participation AS (
    -- Find the earliest event participation date for each member
    SELECT
        member_id,
        MIN(responded_at) AS first_participation_date
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        responded_at IS NOT NULL -- Only consider actual responses/participations
    GROUP BY
        member_id
),
weekly_active_event_members AS (
    -- Get all distinct members who participated in an event in each week
    SELECT
        DATE_TRUNC('week', responded_at) AS week_start_date,
        member_id
    FROM
        {{ ref('stg_event_rsvps') }}
    WHERE
        responded_at IS NOT NULL
    GROUP BY
        1, 2 -- Group by week and member to get distinct weekly participants
),
all_relevant_weeks AS (
    -- Generate a series of weeks from the earliest event participation to the current week
    SELECT week_start_date
    FROM GENERATE_SERIES(
        DATE_TRUNC('week', (SELECT MIN(first_participation_date) FROM member_first_event_participation)),
        DATE_TRUNC('week', CURRENT_DATE),
        '1 week'::interval
    ) AS s(week_start_date)
)
SELECT
    arw.week_start_date,
    -- Count of new event participants for this week:
    -- Those whose first participation date falls exactly within this specific week.
    COUNT(DISTINCT CASE
        WHEN DATE_TRUNC('week', mfep.first_participation_date) = arw.week_start_date
        THEN mfep.member_id
    END) AS new_event_participants_this_week,

    -- Count of returning event participants for this week:
    -- Those who are active in an event this week, AND
    -- whose very first event participation date was *before* this week.
    COUNT(DISTINCT CASE
        WHEN waem.week_start_date = arw.week_start_date -- Active in an event this week
        AND DATE_TRUNC('week', mfep.first_participation_date) < arw.week_start_date -- And their first participation was *before* this week
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