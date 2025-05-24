-- dbt/models/staging/stg_memberships.sql
SELECT
    -- Cast IDs to INT, filtering out non-numeric values
    CASE WHEN memberships.membership_id ~ '^[0-9]+$' THEN memberships.membership_id::INT ELSE NULL END AS membership_id,
    CASE WHEN memberships.team_id ~ '^[0-9]+$' THEN memberships.team_id::INT ELSE NULL END AS team_id,
    CASE WHEN memberships.user_id ~ '^[0-9]+$' THEN memberships.user_id::INT ELSE NULL END AS user_id,
    memberships.role_title,
    -- Safely cast created_at to TIMESTAMPTZ
    CASE WHEN memberships.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN memberships.created_at::TIMESTAMPTZ ELSE NULL END AS created_at
FROM
    {{ ref('memberships') }} AS memberships
WHERE
    -- Filter out rows where IDs are not valid INTs
    (CASE WHEN memberships.membership_id ~ '^[0-9]+$' THEN memberships.membership_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN memberships.team_id ~ '^[0-9]+$' THEN memberships.team_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN memberships.user_id ~ '^[0-9]+$' THEN memberships.user_id::INT ELSE NULL END) IS NOT NULL AND
    memberships.role_title IS NOT NULL AND
    (CASE WHEN memberships.created_at ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$' THEN memberships.created_at::TIMESTAMPTZ ELSE NULL END) IS NOT NULL