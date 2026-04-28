# Irembo TeleClinic Analytics Engineer

This repository contains my **Part 1** written responses and **Part 2** dbt models and tests.

- I used ClickHouse SQL syntax and dbt `source()` / `ref()` patterns throughout.
- I assumed raw sources live under the `teleclinic_raw` source namespace (see `models/staging/sources.yml`).
- I assumed the `consultations` table includes `created_at` and `started_at` as string columns.
- I assumed test accounts are identifiable by `patient_id` values that start with `'TEST_'`.
- I assumed referral flags are available as `clinical_outcomes.referral_issued` and `intake_flags.referral_requested`.
- I treated waits over 12 hours (720 minutes) as implausible for a teleconsult triage flow and set them to NULL rather than dropping the row, so all other metrics for that consultation are preserved.
- I classified referrals into four buckets: `doctor_referral`, `patient_requested_only`, `both`, and `no_referral`.
- Materialization (`table` vs `view`) is noted per model; adjust to your performance and cost requirements.
- MoM spike detection and tz-fix validation are implemented as singular tests in `tests/` (`.sql` files), not as schema-test expressions.
- `dbt_utils` is required for `expression_is_true` schema tests. Add it to `packages.yml`:
  ```yaml
  packages:
    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"] <- Update version according to your system
  ```
- **AI use:** I used AI assistance in two specific places: (1) developing and verifying the regex pattern for extracting and stripping UTC offset strings from `started_at` (the `extract` / `replaceRegexpAll` logic in `stg_consultations_fixed.sql`), and (2) debugging the ClickHouse-specific behavior of `parseDateTimeBestEffortOrNull` and `addMinutes` when chained with `toTimeZone` on malformed timestamp strings.
- The MoM anomaly threshold is fixed at **15 percentage points**. A data-driven threshold (e.g. mean ± 2 Standard Deviation over a rolling window) would be more robust with sufficient historical data and is a natural next step.
