
  
    

  create  table "spond_analytics"."public_public"."events_with_rsvps__dbt_tmp"
  
  
    as
  
  (
    WITH event_rsvps_agg AS (
    SELECT
        event_id,
        COUNT(rsvp_id) AS total_rsvps,
        COUNT(CASE WHEN status = 'accepted' THEN rsvp_id END) AS accepted_rsvps,
        COUNT(CASE WHEN status = 'declined' THEN rsvp_id END) AS declined_rsvps,
        COUNT(CASE WHEN status = 'pending' THEN rsvp_id END) AS pending_rsvps
    FROM
        "spond_analytics"."public_public"."stg_event_rsvps"
    GROUP BY
        event_id
)

SELECT
    e.event_id,
    e.event_start, -- Changed from e.event_name and e.event_time
    e.event_end,
    e.latitude,    -- Changed from e.location
    e.longitude,
    COALESCE(era.total_rsvps, 0) AS total_rsvps,
    COALESCE(era.accepted_rsvps, 0) AS accepted_rsvps,
    COALESCE(era.declined_rsvps, 0) AS declined_rsvps,
    COALESCE(era.pending_rsvps, 0) AS pending_rsvps
FROM
    "spond_analytics"."public_public"."stg_events" AS e
LEFT JOIN
    event_rsvps_agg AS era ON e.event_id = era.event_id
  );
  