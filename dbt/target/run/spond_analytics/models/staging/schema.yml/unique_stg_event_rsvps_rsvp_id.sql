
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    rsvp_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public_public"."stg_event_rsvps"
where rsvp_id is not null
group by rsvp_id
having count(*) > 1



  
  
      
    ) dbt_internal_test