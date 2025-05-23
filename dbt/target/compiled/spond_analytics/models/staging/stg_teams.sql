SELECT
    team_id,
    team_name,
    team_created_at::timestamp as team_created_at -- Cast to timestamp
FROM
    "spond_analytics"."public"."raw_teams" -- 'public' is the default schema for raw tables