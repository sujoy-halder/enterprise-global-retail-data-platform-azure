# Operations

## Core Signals

- Event Hub incoming messages, throttled requests, and consumer lag.
- ADLS Bronze/Silver/Gold file counts and late-arriving partition volume.
- Databricks job success, duration, cluster cost, and Delta table freshness.
- Snowflake warehouse credits, failed queries, dbt test failures, and freshness tests.
- AKS pod restarts, HPA saturation, CPU/memory pressure, and failed probes.
- ADF pipeline failures and integration runtime queue depth.

## Data Quality

The Python contracts reject missing required fields, invalid timestamps, negative quantities, and unknown event types. dbt adds warehouse-level uniqueness, not-null, accepted-values, and relationship checks.

## Incident Triage

1. Check Event Hub ingress and dead-letter counts by event type.
2. Confirm ADLS Bronze partitions are landing for the affected source.
3. Run the Databricks job for a bounded partition.
4. Check dbt test failures and Snowflake load history.
5. Verify Power BI refresh status after Gold and dbt are healthy.

## Recovery

Replay from immutable Bronze files first. Use Event Hubs retention only for events still within the configured retention window. Keep replays idempotent by preserving `event_id` and `source_system`.
