# Part 1: Written Responses

## Q1: What actually happened? (Investigation)
Two different issues happened, and they should be treated separately.

- The referral-rate jump is mainly a metric-definition change, not a sudden clinical behavior change. In February and March, referrals were counted from `clinical_outcomes` only (11.1% and 11.0%). In April, the dashboard started counting both doctor-issued referrals and the new patient intake checkbox (`intake_flags.referral_requested`) after the April 3 product release. Table 2 supports this: doctor-issued referrals were 10.7% (stable vs prior months), while patient-requested referrals contributed an additional 17.3%, which explains the 28.0% total almost entirely. So this is primarily a reporting-definition/platform-change issue.

- The wait-time collapse to 4 minutes is a data-quality bug. `Table 3(Wait time sample)` shows negative wait times beginning April 5, the same date a new doctor app version was released. Those records carry `UTC+2` in `started_at` while `created_at` remains UTC, creating invalid negatives if timestamps are not normalized before subtraction. With ~34% of April records coming from that app version, this can materially distort the mean.

__What still needs verification:__ whether doctors can override patient requests, whether the new checkbox had a default-selected bias, and whether all UTC+2 variants (for example `UTC+2` and `+02:00`) are consistently corrected or if we have any other variation of different timezones in our data to address

## Q2: What to tell Dr. Wangari at 1:45 pm? (Slack Communication)

Dr. Wangari, I have confirmed the two dashboard anomalies have different causes.
- First, the referral jump (11% to 28%) is not showing a true clinical shift in doctor behavior. April reporting started including the new patient intake `"referral requested"` flag (released April 3), which added a large non-clinician component to the count. Doctor-issued referrals are still around the prior baseline.

- Second, the wait-time drop is a data bug tied to the April 5 doctor app release: a subset of records writes consultation start timestamps with a different timezone format, producing invalid negative waits unless normalized.

- __What is confirmed now:__ dashboard values are currently not comparable month-to-month without correction.

- __What is still in progress:__  final validation of all affected records and full backfill of corrected wait-time calculations.

In summary, the reported April spikes are data-definition/data-quality issues; corrected figures are being validated and will be shared as soon as the team fully validates all data and renormalizes them.

# Part 2
## Github link repo
**https://github.com/nacali07/Callixte_Irembo_Anyalytics_Engineer.git**

Please follow this link. Note that part 2 has the following file structure:

```plaintext
CALLIXTE_IREMBO_ANYALYTICS_ENGINEER/
├─ models/
│  ├─ intermediate/
│  │  ├─ int_consultations_enriched.sql
│  │  └─ int_referrals_classified.sql
│  ├─ marts/
│  │  ├─ fct_consultations.sql
│  │  └─ mart_referral_rate_monthly.sql
│  ├─ staging/
│  │  ├─ sources.yml
│  │  ├─ stg_clinical_outcomes.sql
│  │  ├─ stg_consultation_requests.sql
│  │  ├─ stg_consultations_fixed.sql
│  │  ├─ stg_consultations.sql
│  │  └─ stg_providers.sql
│  └─ schema_tests.yml
├─ tests/
│  ├─ test_no_negative_wait_after_tz_fix.sql
│  └─ test_referral_rate_mom_spike.sql
├─ questions.md
├─ README.md
└─ written_responses.md
```
