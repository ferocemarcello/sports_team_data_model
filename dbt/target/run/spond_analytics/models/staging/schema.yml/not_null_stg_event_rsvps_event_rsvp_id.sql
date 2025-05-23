
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select event_rsvp_id
from "spond_analytics"."public"."stg_event_rsvps"
where event_rsvp_id is null



  
  
      
    ) dbt_internal_test