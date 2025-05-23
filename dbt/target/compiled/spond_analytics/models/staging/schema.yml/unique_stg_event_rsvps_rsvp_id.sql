
    
    

select
    rsvp_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public_public"."stg_event_rsvps"
where rsvp_id is not null
group by rsvp_id
having count(*) > 1


