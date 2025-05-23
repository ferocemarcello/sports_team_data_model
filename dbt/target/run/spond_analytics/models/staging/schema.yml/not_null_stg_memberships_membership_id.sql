
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select membership_id
from "spond_analytics"."public"."stg_memberships"
where membership_id is null



  
  
      
    ) dbt_internal_test