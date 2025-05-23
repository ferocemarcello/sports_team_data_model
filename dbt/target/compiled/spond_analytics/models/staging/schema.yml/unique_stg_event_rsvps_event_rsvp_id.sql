
    
    

select
    event_rsvp_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public"."stg_event_rsvps"
where event_rsvp_id is not null
group by event_rsvp_id
having count(*) > 1


