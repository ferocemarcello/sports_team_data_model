
  create view "spond_analytics"."public_public"."stg_teams__dbt_tmp"
    
    
  as (
    SELECT
    team_id,
    team_name,
    team_created_at::timestamp as team_created_at -- Cast to timestamp
FROM
    "spond_analytics"."public"."raw_teams" -- 'public' is the default schema for raw tables
  );