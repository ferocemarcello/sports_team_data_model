
  
    

  create  table "spond_analytics"."public"."stg_teams__dbt_tmp"
  
  
    as
  
  (
    -- dbt/models/staging/stg_teams.sql
SELECT
    team_id,
    team_activity AS team_name,        -- Renaming team_activity to team_name
    country_code,
    created_at AS team_created_at     -- Renaming created_at to team_created_at
FROM
    "spond_analytics"."public"."raw_teams"
  );
  