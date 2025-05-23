
  create view "spond_analytics"."public_public"."stg_events__dbt_tmp"
    
    
  as (
    SELECT
    event_id,
    team_id,
    event_name,
    event_time::timestamp as event_time, -- Cast to timestamp
    location
FROM
    "spond_analytics"."public"."raw_events"
  );