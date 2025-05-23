
    
    

with child as (
    select event_id as from_field
    from "spond_analytics"."public_public"."stg_event_rsvps"
    where event_id is not null
),

parent as (
    select event_id as to_field
    from "spond_analytics"."public_public"."stg_events"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


