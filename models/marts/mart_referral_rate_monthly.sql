-- order_by sets the ClickHouse MergeTree physical sort key.
-- Consumers must apply their own ORDER BY; SELECT-level ORDER BY on a materialized
-- table in ClickHouse does not guarantee storage or query result order.
{{ config(materialized='table', order_by='report_month') }}

SELECT
    toStartOfMonth(created_at_utc) AS report_month,
    count() AS total_consultations,
    countIf(is_doctor_referral = 1) AS doctor_referrals,
    round(100.0 * countIf(is_doctor_referral = 1) / nullIf(count(), 0), 1) AS doctor_referral_rate_pct,
    countIf(is_patient_requested = 1) AS patient_requested_referrals,
    round(100.0 * countIf(is_patient_requested = 1) / nullIf(count(), 0), 1) AS patient_requested_rate_pct,
    countIf(referral_type = 'both') AS both_referrals,
    round(100.0 * countIf(referral_type != 'no_referral') / nullIf(count(), 0), 1) AS dashboard_referral_rate_pct
FROM {{ ref('int_referrals_classified') }}
GROUP BY report_month

-- Metric definition:
-- The clinical KPI is doctor_referral_rate_pct because it captures clinician decisions and stays comparable to pre-April months.
-- Patient-requested referrals are tracked separately in patient_requested_rate_pct because they represent patient intent, not clinical adjudication.
-- Consultations classified as "both" are counted in both component rates for transparency, while dashboard_referral_rate_pct counts them once.
-- This split preserves trend comparability while still surfacing product-intake behavior for operational analysis.
