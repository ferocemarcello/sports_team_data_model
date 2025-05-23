
  create view "spond_analytics"."public_public"."stg_event_rsvps__dbt_tmp"
    
    
  as (
    -- dbt/models/staging/stg_event_rsvps.sql
SELECT
    event_rsvp_id AS rsvp_id,    -- Renaming event_rsvp_id to rsvp_id
    event_id,
    membership_id AS member_id, -- Assuming membership_id maps to member_id
    rsvp_status AS status,      -- Renaming rsvp_status to status
    responded_at AS rsvp_time   -- Renaming responded_at to rsvp_time
FROM
    "spond_analytics"."public"."raw_event_rsvps"
  );