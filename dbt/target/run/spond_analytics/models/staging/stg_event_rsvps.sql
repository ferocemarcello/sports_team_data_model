
  
    

  create  table "spond_analytics"."public"."stg_event_rsvps__dbt_tmp"
  
  
    as
  
  (
    -- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,
    responded_at
FROM "spond_analytics"."public"."event_rsvps" AS event_rsvps
INNER JOIN "spond_analytics"."public"."stg_events" AS events
    ON event_rsvps.event_id = events.event_id
INNER JOIN "spond_analytics"."public"."stg_memberships" AS memberships
    ON event_rsvps.membership_id = memberships.membership_id
WHERE rsvp_status IN ('0', '1', '2')
  );
  