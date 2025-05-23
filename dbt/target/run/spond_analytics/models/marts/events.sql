
  
    

  create  table "spond_analytics"."public"."events__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    event_id,
    team_id,
    event_start,
    event_end,
    latitude,
    longitude,
    created_at
FROM "spond_analytics"."public"."stg_events"
  );
  