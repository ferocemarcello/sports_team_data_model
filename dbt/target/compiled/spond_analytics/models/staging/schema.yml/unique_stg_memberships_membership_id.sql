
    
    

select
    membership_id as unique_field,
    count(*) as n_records

from "spond_analytics"."public_public"."stg_memberships"
where membership_id is not null
group by membership_id
having count(*) > 1


