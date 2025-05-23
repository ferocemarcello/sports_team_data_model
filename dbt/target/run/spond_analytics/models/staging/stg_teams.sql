
  
    

  create  table "spond_analytics"."public"."stg_teams__dbt_tmp"
  
  
    as
  
  (
    -- dbt/models/staging/stg_teams.sql
SELECT
    team_id,
    team_activity,
    country_code,
    created_at
FROM
    "spond_analytics"."public"."teams"
  );
  