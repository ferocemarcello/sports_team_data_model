{{ config(materialized='table') }}

SELECT
    event_id,
    team_id,
    event_time, -- From stg_events where event_start AS event_time
    event_end,
    latitude,
    longitude,
    created_at
FROM {{ ref('stg_events') }}