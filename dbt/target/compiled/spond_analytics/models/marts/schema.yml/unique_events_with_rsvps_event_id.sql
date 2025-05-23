
    
    

select
    event_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public"."events_with_rsvps"
where event_id is not null
group by event_id
having count(*) > 1


