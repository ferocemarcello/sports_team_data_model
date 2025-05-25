SELECT
    events.event_id,
    events.team_id,
    EXTRACT(EPOCH FROM events.event_start)::BIGINT AS event_start,
    EXTRACT(EPOCH FROM events.event_end)::BIGINT AS event_end,
    events.latitude,
    events.longitude,
    EXTRACT(EPOCH FROM events.created_at)::BIGINT AS created_at
FROM
    {{ ref('events') }} AS events
INNER JOIN
    {{ ref('stg_teams') }} AS teams
    ON events.team_id = teams.team_id
WHERE
    events.event_id IS NOT NULL AND
    events.team_id IS NOT NULL