# Questions for the Hiring Team

1. Besides `UTC+2`, what other timezone offset formats appear in the raw `started_at` field? For example, does `+02:00` (ISO 8601) or a named zone like `Africa/Kigali` occur in production data? This affects whether the current regex covers all cases.

2. Can a single `consultation_id` have more than one row in `clinical_outcomes` — for example, if a doctor amends an outcome after submission? This determines whether `max(referral_issued)` is the right aggregation or whether a versioning field should drive the canonical outcome.

3. When the "referral requested" checkbox was released on April 3, was it opt-in (unchecked by default) or pre-selected for all patients? And does a patient's selection require any doctor confirmation before it writes to `intake_flags.referral_requested`?

4. Is `consultation_id` guaranteed unique in the raw `consultations` table, or can a consultation be re-submitted and appear as multiple rows with the same ID?

5. Before April, was the referral figure reported to the Ministry sourced from `clinical_outcomes` only, or from a combined count that also included other sources?

6. If a doctor explicitly removes or rejects a patient-requested referral during the consultation, is `intake_flags.referral_requested` updated to false, or does it remain true permanently as a record of patient intent?
