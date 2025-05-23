
  create view "spond_analytics"."public_public"."stg_event_rsvps__dbt_tmp"
    
    
  as (
    SELECT
    rsvp_id,
    event_id,
    member_id,
    status,
    rsvp_time::timestamp as rsvp_time -- Cast to timestamp
FROM
    "spond_analytics"."public"."raw_event_rsvps"
  );