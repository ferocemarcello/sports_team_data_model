
  
    

  create  table "spond_analytics"."public"."events__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    event_id,
    team_id,
    event_time, -- From stg_events where event_start AS event_time
    event_end,
    latitude,
    longitude,
    created_at
FROM "spond_analytics"."public"."stg_events"
  );
  