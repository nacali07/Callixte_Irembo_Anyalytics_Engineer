{{ config(materialized='table') }}

WITH completed_consults AS (
    SELECT
        consultation_id,
        -- argMax is deterministic: picks created_at_utc from the row where
        -- created_at_utc is latest. Safe even if duplicates ever slip through staging.
        argMax(created_at_utc, created_at_utc) AS created_at_utc
    FROM {{ ref('stg_consultations_fixed') }}
    -- Only consultations with a valid, plausible wait time flow into referral counts.
    -- This propagates the 720-min quality threshold from staging into the denominator.
    WHERE wait_minutes IS NOT NULL
    GROUP BY consultation_id
),
doctor_outcomes AS (
    SELECT
        consultation_id,
        max(referral_issued) AS referral_issued
    FROM {{ ref('stg_clinical_outcomes') }}
    GROUP BY consultation_id
),
patient_requests AS (
    SELECT
        consultation_id,
        max(referral_requested) AS referral_requested
    FROM {{ ref('stg_consultation_requests') }}
    GROUP BY consultation_id
)
SELECT
    c.consultation_id,
    c.created_at_utc,
    -- coalesce handles LEFT JOIN NULLs (consultations with no matching outcome row).
    -- Upstream staging already guarantees 0/1 within matched rows.
    toUInt8(coalesce(d.referral_issued,   0)) AS is_doctor_referral,
    toUInt8(coalesce(r.referral_requested, 0)) AS is_patient_requested,
    -- References the aliases computed above; avoids repeating coalesce logic.
    -- ClickHouse resolves same-SELECT aliases in column definition order.
    CASE
        WHEN is_doctor_referral = 1 AND is_patient_requested = 1 THEN 'both'
        WHEN is_doctor_referral = 1                               THEN 'doctor_referral'
        WHEN is_patient_requested = 1                             THEN 'patient_requested_only'
        ELSE                                                           'no_referral'
    END AS referral_type
FROM completed_consults c
LEFT JOIN doctor_outcomes  d USING (consultation_id)
LEFT JOIN patient_requests r USING (consultation_id)
