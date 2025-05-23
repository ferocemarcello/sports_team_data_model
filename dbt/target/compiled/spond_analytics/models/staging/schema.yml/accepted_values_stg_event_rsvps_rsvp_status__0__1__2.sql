
    
    

with all_values as (

    select
        rsvp_status as value_field,
        count(*) as n_records

    from "spond_analytics"."public"."stg_event_rsvps"
    group by rsvp_status

)

select *
from all_values
where value_field not in (
    '0','1','2'
)


