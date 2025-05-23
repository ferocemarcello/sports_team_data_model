SELECT
    membership_id,
    team_id,
    member_id,
    is_admin::boolean as is_admin -- Cast to boolean
FROM
    {{ source('public', 'raw_memberships') }}