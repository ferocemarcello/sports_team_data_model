SELECT
    memberships.id AS membership_id,
    memberships.team_id,
    memberships.role_title,
    memberships.joined_at
FROM "spond_analytics"."public"."raw_memberships" AS memberships
INNER JOIN "spond_analytics"."public"."raw_teams" AS teams -- Ensures team_id exists in raw_teams
  ON memberships.team_id = teams.team_id -- CORRECTED: changed to teams.team_id