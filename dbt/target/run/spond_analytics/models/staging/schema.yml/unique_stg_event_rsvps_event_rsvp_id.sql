
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    event_rsvp_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public"."stg_event_rsvps"
where event_rsvp_id is not null
group by event_rsvp_id
having count(*) > 1



  
  
      
    ) dbt_internal_test