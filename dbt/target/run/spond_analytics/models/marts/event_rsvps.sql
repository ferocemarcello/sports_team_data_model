
  
    

  create  table "spond_analytics"."public"."event_rsvps__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    rsvp_id,
    event_id,
    membership_id,
    status,
    rsvp_time -- From stg_event_rsvps where responded_at AS rsvp_time
FROM "spond_analytics"."public"."stg_event_rsvps"
  );
  