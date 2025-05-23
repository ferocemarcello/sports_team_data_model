{{ config(materialized='table') }}

SELECT
    membership_id,
    team_id,
    role_title,
    joined_at
FROM {{ ref('stg_memberships') }}