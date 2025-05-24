-- dbt/models/staging/memberships.sql
SELECT
    TRY_CAST(membership_id AS INT) AS membership_id, -- Keep as VARCHAR if it's a string ID
    TRY_CAST(team_id AS INT) AS team_id,             -- Keep as VARCHAR if it's a string ID
    TRY_CAST(user_id AS INT) AS user_id,             -- Keep as VARCHAR if it's a string ID
    TRY_CAST(is_admin AS BOOLEAN) AS is_admin,           -- Cast to BOOLEAN
    TRY_CAST(created_at AS TIMESTAMPTZ) AS created_at    -- Cast to TIMESTAMPTZ
FROM
    {{ ref('memberships') }}
WHERE
    -- Filter out rows with invalid types
    TRY_CAST(membership_id AS INT) IS NOT NULL AND
    TRY_CAST(team_id AS INT) IS NOT NULL AND
    TRY_CAST(user_id AS INT) IS NOT NULL AND
    TRY_CAST(is_admin AS BOOLEAN) IS NOT NULL AND
    TRY_CAST(created_at AS TIMESTAMPTZ) IS NOT NULL