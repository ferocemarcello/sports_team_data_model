{{ config(materialized='table') }}

SELECT
    event_rsvp_id,
    event_id,
    membership_id,
    rsvp_status,
    rsvp_time -- From stg_event_rsvps where responded_at AS rsvp_time
FROM {{ ref('stg_event_rsvps') }}