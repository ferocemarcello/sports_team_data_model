
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "spond_analytics"."public_public"."stg_event_rsvps"
    group by status

)

select *
from all_values
where value_field not in (
    'accepted','declined','pending'
)


