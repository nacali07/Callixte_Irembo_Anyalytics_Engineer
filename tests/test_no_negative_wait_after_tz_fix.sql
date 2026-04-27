-- Singular test: no record may have a negative wait_minutes after tz normalization.
--
-- Checks ALL records, not just is_tz_corrected = 1.
-- Reason: a record where tz detection failed silently (e.g. unrecognised offset format)
-- would have is_tz_corrected = 0 but still produce a negative wait. Scoping to
-- is_tz_corrected = 1 only would miss that class of bug.
--
-- NULL wait_minutes (implausibly large waits, nulled by the 720-min threshold) are
-- excluded — they are not failures; they are intentionally suppressed by the model.
-- Returns rows on failure. Empty result = test passes.
-- Any failure here must block the monthly dashboard from being published.

SELECT
    consultation_id,
    created_at_utc,
    started_at_utc,
    is_tz_corrected,
    wait_minutes
FROM {{ ref('stg_consultations_fixed') }}
WHERE wait_minutes < 0
