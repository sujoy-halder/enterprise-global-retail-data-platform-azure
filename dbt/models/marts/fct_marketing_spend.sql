select
    cast(campaign_event_at as date) as campaign_date,
    campaign_id,
    channel,
    currency,
    sum(spend_amount) as spend_amount
from {{ ref('stg_marketing_campaigns') }}
group by 1, 2, 3, 4
