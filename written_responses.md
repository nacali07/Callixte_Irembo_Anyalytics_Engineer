# Part 1: Written Responses

## Q1: What actually happened? (Investigation)
Two different issues happened, and they should be treated separately.

The referral-rate jump is mainly a metric-definition change, not a sudden clinical behavior change. In February and March, referrals were counted from `clinical_outcomes` only (11.1% and 11.0%). In April, the dashboard started counting both doctor-issued referrals and the new patient intake checkbox (`intake_flags.referral_requested`) after the April 3 product release. Table 2 supports this: doctor-issued referrals were 10.7% (stable vs prior months), while patient-requested referrals contributed an additional 17.3%, which explains the 28.0% total almost entirely. So this is primarily a reporting-definition/platform-change issue.

The wait-time collapse to 4 minutes is a data-quality bug. `Table 3(Wait time sample)` shows negative wait times beginning April 5, the same date a new doctor app version was released. Those records carry `UTC+2` in `started_at` while `created_at` remains UTC, creating invalid negatives if timestamps are not normalized before subtraction. With ~34% of April records coming from that app version, this can materially distort the mean.

What still needs verification: whether doctors can override patient requests, whether the new checkbox had a default-selected bias, and whether all UTC+2 variants (for example `UTC+2` and `+02:00`) are consistently corrected or if we have any other variation of offset from UTC timezone in our data.
