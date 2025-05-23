
  
    

  create  table "spond_analytics"."public"."stg_memberships__dbt_tmp"
  
  
    as
  
  (
    SELECT
    memberships.membership_id,
    memberships.team_id,
    memberships.role_title,
    memberships.joined_at
FROM "spond_analytics"."public"."memberships" AS memberships
INNER JOIN "spond_analytics"."public"."teams" AS teams
  ON memberships.team_id = teams.team_id
  );
  