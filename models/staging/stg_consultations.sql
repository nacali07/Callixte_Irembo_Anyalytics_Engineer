{{ config(materialized='view') }}

SELECT
    consultation_id,
    patient_id,
    parseDateTimeBestEffortOrNull(created_at) AS created_at_utc,
    parseDateTimeBestEffortOrNull(started_at) AS started_at_utc,
    dateDiff('minute', created_at_utc, started_at_utc) AS wait_time_minutes
FROM {{ source('teleclinic_raw', 'consultations') }}
WHERE NOT startsWith(patient_id, 'TEST_')
