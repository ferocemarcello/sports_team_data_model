SELECT
    memberships.membership_id AS membership_id, -- CORRECTED: changed to memberships.membership_id
    memberships.team_id, -- This was already correct in previous instructions
    memberships.role_title,
    memberships.joined_at
FROM "spond_analytics"."public"."raw_memberships" AS memberships
INNER JOIN "spond_analytics"."public"."raw_teams" AS teams
  ON memberships.team_id = teams.team_id