
  
    

  create  table "spond_analytics"."public"."stg_event_rsvps__dbt_tmp"
  
  
    as
  
  (
    -- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,
    rsvp_time
FROM "spond_analytics"."public"."event_rsvps"
WHERE rsvp_status IN ('accepted', 'declined', 'pending')
  );
  