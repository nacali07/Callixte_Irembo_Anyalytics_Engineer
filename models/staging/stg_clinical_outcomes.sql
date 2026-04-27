{{ config(materialized='view') }}

SELECT
    consultation_id,
    toUInt8(coalesce(referral_issued, 0)) AS referral_issued
FROM {{ source('teleclinic_raw', 'clinical_outcomes') }}
