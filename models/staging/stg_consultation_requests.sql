{{ config(materialized='view') }}

SELECT
    consultation_id,
    toUInt8(coalesce(referral_requested, 0)) AS referral_requested
FROM {{ source('teleclinic_raw', 'intake_flags') }}
