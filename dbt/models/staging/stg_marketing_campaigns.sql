select
    cast(event_id as varchar) as event_id,
    cast(event_time as timestamp_ntz) as campaign_event_at,
    cast(campaign_id as varchar) as campaign_id,
    cast(channel as varchar) as channel,
    cast(spend_amount as number(18, 4)) as spend_amount,
    upper(cast(currency as varchar)) as currency,
    cast(processed_at as timestamp_ntz) as processed_at
from {{ source('raw', 'marketing_campaigns') }}
where quality_status = 'accepted'
