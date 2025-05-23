
  
    

  create  table "spond_analytics"."public_public"."teams__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    team_id,
    team_name,
    team_created_at
FROM
    "spond_analytics"."public_public"."stg_teams"
  );
  