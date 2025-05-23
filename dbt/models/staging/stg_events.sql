SELECT
    event_id,
    team_id,
    event_name,
    event_time::timestamp as event_time, -- Cast to timestamp
    location
FROM
    {{ source('public', 'raw_events') }}