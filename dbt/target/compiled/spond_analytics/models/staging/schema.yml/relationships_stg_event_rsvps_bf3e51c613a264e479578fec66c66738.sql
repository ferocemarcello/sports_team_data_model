
    
    

with child as (
    select membership_id as from_field
    from "spond_analytics"."public"."stg_event_rsvps"
    where membership_id is not null
),

parent as (
    select membership_id as to_field
    from "spond_analytics"."public"."stg_memberships"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


