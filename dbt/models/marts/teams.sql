{{ config(
    materialized='table',  -- Materialize as a table (instead of default view)
    schema='public'        -- Explicitly set the schema for this model
)}}

SELECT
    team_id,
    team_name,
    team_created_at
FROM
    {{ ref('stg_teams') }}