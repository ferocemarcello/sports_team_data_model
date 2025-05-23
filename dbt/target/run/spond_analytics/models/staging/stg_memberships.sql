
  create view "spond_analytics"."public_public"."stg_memberships__dbt_tmp"
    
    
  as (
    -- dbt/models/staging/stg_memberships.sql
SELECT
    membership_id,
    team_id,
    -- member_id, -- This column is not directly in memberships.csv
    -- is_admin::boolean as is_admin, -- This column is not directly in memberships.csv
    role_title, -- From CSV
    joined_at   -- From CSV
FROM
    "spond_analytics"."public"."raw_memberships"
  );