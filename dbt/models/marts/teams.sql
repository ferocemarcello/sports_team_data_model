{{ config(
    materialized='table'   -- Keep this line to ensure it's a table
)}}

SELECT
    team_id,
    team_name,
    team_created_at
FROM
    {{ ref('stg_teams') }}