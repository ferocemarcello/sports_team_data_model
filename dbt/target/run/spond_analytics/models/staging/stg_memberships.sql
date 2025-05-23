
  create view "spond_analytics"."public_public"."stg_memberships__dbt_tmp"
    
    
  as (
    SELECT
    membership_id,
    team_id,
    member_id,
    is_admin::boolean as is_admin -- Cast to boolean
FROM
    "spond_analytics"."public"."raw_memberships"
  );