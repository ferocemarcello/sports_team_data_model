-- dbt/models/staging/stg_memberships.sql
SELECT
    -- Use CASE for robust type casting for IDs (assuming they are string IDs)
    CASE WHEN memberships.membership_id ~ '^[0-9A-Za-z-]+$' THEN memberships.membership_id ELSE NULL END AS membership_id,
    CASE WHEN memberships.team_id ~ '^[0-9A-Za-z-]+$' THEN memberships.team_id ELSE NULL END AS team_id,
    CASE WHEN memberships.user_id ~ '^[0-9A-Za-z-]+$' THEN memberships.user_id ELSE NULL END AS user_id,
    memberships.role_title,
    -- Safely cast created_at to TIMESTAMPTZ
    CASE WHEN memberships.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN memberships.created_at::TIMESTAMPTZ ELSE NULL END AS created_at
FROM
    {{ ref('memberships') }} AS memberships
WHERE
    -- Filter out rows with invalid types based on CASE statement output
    (CASE WHEN memberships.membership_id ~ '^[0-9A-Za-z-]+$' THEN memberships.membership_id ELSE NULL END) IS NOT NULL AND
    (CASE WHEN memberships.team_id ~ '^[0-9A-Za-z-]+$' THEN memberships.team_id ELSE NULL END) IS NOT NULL AND
    (CASE WHEN memberships.user_id ~ '^[0-9A-Za-z-]+$' THEN memberships.user_id ELSE NULL END) IS NOT NULL AND
    memberships.role_title IS NOT NULL AND -- <--- ADDED NOT NULL CHECK FOR role_title
    (CASE WHEN memberships.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN memberships.created_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL