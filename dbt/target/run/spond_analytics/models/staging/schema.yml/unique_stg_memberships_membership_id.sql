
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    membership_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public_public"."stg_memberships"
where membership_id is not null
group by membership_id
having count(*) > 1



  
  
      
    ) dbt_internal_test