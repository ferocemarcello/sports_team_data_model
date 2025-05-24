-- dbt/models/staging/stg_memberships.sql
SELECT
    -- Cast IDs to INT, filtering out non-numeric values
    CASE WHEN memberships.membership_id ~ '^[0-9]+$' THEN memberships.membership_id::INT ELSE NULL END AS membership_id,
    CASE WHEN memberships.team_id ~ '^[0-9]+$' THEN memberships.team_id::INT ELSE NULL END AS team_id,
    memberships.role_title,
    EXTRACT(EPOCH FROM memberships.joined_at)::BIGINT AS joined_at
FROM
    {{ ref('memberships') }} AS memberships
WHERE
    -- Filter out rows where IDs are not valid INTs
    (CASE WHEN memberships.membership_id ~ '^[0-9]+$' THEN memberships.membership_id::INT ELSE NULL END) IS NOT NULL AND
    (CASE WHEN memberships.team_id ~ '^[0-9]+$' THEN memberships.team_id::INT ELSE NULL END) IS NOT NULL AND
    memberships.role_title IS NOT NULL AND
    memberships.joined_at IS NOT NULL