SELECT
    memberships.membership_id,
    memberships.team_id,
    memberships.role_title,
    EXTRACT(EPOCH FROM memberships.joined_at)::BIGINT AS joined_at
FROM
    {{ ref('memberships') }} AS memberships
INNER JOIN
    {{ ref('stg_teams') }} AS teams
    ON memberships.team_id = teams.team_id
WHERE
    memberships.membership_id IS NOT NULL AND
    memberships.team_id IS NOT NULL AND
    memberships.role_title NOT IN ('admin', 'member')