{{ config(materialized='table') }}

SELECT
    event_id,
    team_id,
    event_start,
    event_end,
    latitude,
    longitude,
    created_at
FROM {{ ref('stg_events') }}