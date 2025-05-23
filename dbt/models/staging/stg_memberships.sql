SELECT
    memberships.membership_id,
    memberships.team_id,
    memberships.role_title,
    memberships.joined_at
FROM {{ source('public', 'raw_memberships') }} AS memberships
INNER JOIN {{ source('public', 'raw_teams') }} AS teams
  ON memberships.team_id = teams.team_id