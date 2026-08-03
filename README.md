
### Cost-aware development

The project uses configurable `ga4_start_date` and `ga4_end_date`
variables to control the source-table range.

Development initially used the four-day Black Friday–Cyber Monday
window, providing a small but behaviorally rich dataset for validating
model grains, transaction deduplication, funnel logic, and product
identity.

After validation, the repository defaults were promoted to the complete
2020-11-01 through 2021-01-31 dataset. The full project completed
successfully with 8 models and 53 data tests.

BigQuery query usage was monitored through
`INFORMATION_SCHEMA.JOBS_BY_PROJECT` to track jobs, bytes processed,
and bytes billed.
