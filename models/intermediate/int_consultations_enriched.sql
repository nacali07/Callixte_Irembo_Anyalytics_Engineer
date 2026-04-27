{{ config(materialized='view') }}

SELECT
    consultation_id,
    patient_id,
    created_at_utc,
    started_at_utc,
    is_tz_corrected,
    wait_minutes
FROM {{ ref('stg_consultations_fixed') }}
