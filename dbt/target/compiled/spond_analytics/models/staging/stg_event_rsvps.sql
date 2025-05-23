SELECT
    rsvp_id,
    event_id,
    member_id,
    status,
    rsvp_time::timestamp as rsvp_time -- Cast to timestamp
FROM
    "spond_analytics"."public"."raw_event_rsvps"