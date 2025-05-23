{{ config(
    materialized='table',
    schema='public'
)}}

SELECT
    team_id,
    team_name,
    team_created_at
FROM
    {{ ref('stg_teams') }}