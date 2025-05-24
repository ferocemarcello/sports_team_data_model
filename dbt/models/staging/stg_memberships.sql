-- dbt/models/staging/stg_memberships.sql
SELECT
    memberships.membership_id AS membership_id,
    memberships.team_id AS team_id,
    memberships.role_title,
    EXTRACT(EPOCH FROM memberships.joined_at)::BIGINT AS joined_at
FROM
    {{ ref('memberships') }} AS memberships
WHERE
    memberships.membership_id IS NOT NULL AND
    memberships.team_id IS NOT NULL AND
    memberships.role_title IS NOT IN ('admin, member')