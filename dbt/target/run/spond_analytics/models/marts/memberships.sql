
  
    

  create  table "spond_analytics"."public"."memberships__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    membership_id
    team_id,
    role_title,
    joined_at
FROM "spond_analytics"."public"."stg_memberships"
  );
  