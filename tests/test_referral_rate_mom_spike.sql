-- Singular test: upward month-over-month spike in the clinical referral rate.
--
-- Direction: UPWARD ONLY (delta_pct > 15, not abs > 15).
-- Rationale: an unexpected rise in the referral rate is the primary risk signal
-- in this context — it is what triggered the April dashboard escalation to the
-- Ministry. A downward drop may have a legitimate clinical explanation (new
-- specialist capacity, triage protocol change) and warrants review but not an
-- automatic hard block. If bidirectional detection is needed later, change to
-- abs(delta_pct) > 15 and document the reasoning.
--
-- Threshold: 15 percentage points (absolute, fixed).
-- Feb and March baselines (~11%) imply natural month-to-month variance well
-- under 5 ppt. 15 ppt is conservative. Replace with a rolling mean ± 2 SD
-- threshold once 6+ months of history are available.
--
-- Returns rows on failure. Empty result = test passes.

WITH monthly AS (
    SELECT
        report_month,
        doctor_referral_rate_pct,
        total_consultations
    FROM {{ ref('mart_referral_rate_monthly') }}
),
with_prev AS (
    SELECT
        curr.report_month                                              AS report_month,
        curr.doctor_referral_rate_pct                                  AS current_rate_pct,
        prev.doctor_referral_rate_pct                                  AS previous_rate_pct,
        curr.doctor_referral_rate_pct - prev.doctor_referral_rate_pct  AS delta_pct,
        curr.total_consultations                                       AS current_consults,
        prev.total_consultations                                       AS previous_consults
    FROM monthly curr
    LEFT JOIN monthly prev
        ON prev.report_month = toStartOfMonth(dateAdd(month, -1, curr.report_month))
    WHERE prev.report_month IS NOT NULL
)
SELECT
    report_month,
    current_rate_pct,
    previous_rate_pct,
    delta_pct,
    current_consults,
    previous_consults
FROM with_prev
WHERE delta_pct > 15
