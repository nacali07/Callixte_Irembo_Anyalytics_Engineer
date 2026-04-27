{{ config(materialized='view') }}

WITH base AS (
    SELECT
        consultation_id,
        patient_id,
        created_at,
        started_at
    FROM {{ source('teleclinic_raw', 'consultations') }}
    -- Case-insensitive TEST_ filter: catches test_, Test_, TEST_ etc.
    WHERE NOT startsWith(upper(patient_id), 'TEST_')
),
parsed AS (
    SELECT
        consultation_id,
        patient_id,
        toTimeZone(parseDateTimeBestEffortOrNull(created_at), 'UTC') AS created_at_utc,
        -- Extract the sign character (+/-) from any UTC±N or UTC±N:MM suffix.
        -- Returns '' (empty string) when no offset is present or started_at is NULL.
        extract(started_at, '(?i)UTC\\s*([+-])') AS tz_sign,
        toInt32OrZero(extract(started_at, '(?i)UTC\\s*[+-]\\s*(\\d{1,2})')) AS tz_hour_part,
        toInt32OrZero(extract(started_at, '(?i)UTC\\s*[+-]\\s*\\d{1,2}\\s*:?(\\d{2})')) AS tz_minute_part,
        -- Strip the UTC offset from the string, then collapse any resulting
        -- multi-whitespace (e.g. "2026-04-05  14:30:00") to a single space.
        replaceRegexpAll(
            trim(replaceRegexpAll(
                started_at,
                '(?i)\\s*UTC\\s*[+-]\\s*\\d{1,2}(?::?\\d{2})?\\s*',
                ' '
            )),
            '\\s{2,}',
            ' '
        ) AS started_at_without_offset,
        started_at
    FROM base
),
normalized AS (
    SELECT
        consultation_id,
        patient_id,
        created_at_utc,
        -- Flag whenever a UTC offset sign is detected, regardless of magnitude.
        -- toUInt8 coerces NULL (when started_at is NULL) to 0 safely.
        -- UTC+0 is correctly flagged as corrected even though the math is a no-op.
        toUInt8(tz_sign IN ('+', '-')) AS is_tz_corrected,
        -- Apply offset math only when the offset is non-zero (preserves existing math).
        -- For UTC+0, the else branch parses the full original string — same result.
        if(
            (tz_sign IN ('+', '-') AND (tz_hour_part > 0 OR tz_minute_part > 0)),
            addMinutes(
                toTimeZone(parseDateTimeBestEffortOrNull(started_at_without_offset), 'UTC'),
                -(
                    multiIf(
                        tz_sign = '-', -1,
                        tz_sign = '+',  1,
                        0
                    ) * (tz_hour_part * 60 + tz_minute_part)
                )
            ),
            toTimeZone(parseDateTimeBestEffortOrNull(started_at), 'UTC')
        ) AS started_at_utc
    FROM parsed
),
with_wait AS (
    SELECT
        consultation_id,
        patient_id,
        created_at_utc,
        started_at_utc,
        is_tz_corrected,
        dateDiff('minute', created_at_utc, started_at_utc) AS wait_minutes_raw
    FROM normalized
)
SELECT
    consultation_id,
    patient_id,
    created_at_utc,
    started_at_utc,
    is_tz_corrected,
    -- Threshold: waits outside [0, 720 min] are set to NULL, not dropped.
    -- The row is preserved so all other metrics (referral classification) remain usable.
    if(wait_minutes_raw >= 0 AND wait_minutes_raw <= 720, wait_minutes_raw, NULL) AS wait_minutes
FROM with_wait
