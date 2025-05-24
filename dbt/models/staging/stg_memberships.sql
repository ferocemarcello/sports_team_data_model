-- dbt/models/staging/memberships.sql
SELECT
    TRY_CAST(membership_id AS INT) AS membership_id,
    TRY_CAST(team_id AS INT) AS team_id,
    TRY_CAST(user_id AS INT) AS user_id,
    role_title
    TRY_CAST(created_at AS TIMESTAMPTZ) AS created_at    -- Cast to TIMESTAMPTZ
FROM
    {{ ref('memberships') }}
WHERE
    -- Filter out rows with invalid types
    TRY_CAST(membership_id AS INT) IS NOT NULL AND
    TRY_CAST(team_id AS INT) IS NOT NULL AND
    TRY_CAST(user_id AS INT) IS NOT NULL AND
    role_title
    TRY_CAST(created_at AS TIMESTAMPTZ) IS NOT NULL