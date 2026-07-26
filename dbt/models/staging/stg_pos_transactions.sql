select
    cast(event_id as varchar) as event_id,
    cast(event_time as timestamp_ntz) as sold_at,
    cast(store_id as varchar) as store_id,
    cast(terminal_id as varchar) as terminal_id,
    cast(transaction_id as varchar) as transaction_id,
    cast(product_id as varchar) as product_id,
    cast(quantity as number(18, 4)) as quantity,
    cast(gross_amount as number(18, 4)) as gross_amount,
    upper(cast(currency as varchar)) as currency,
    cast(processed_at as timestamp_ntz) as processed_at
from {{ source('raw', 'pos_transactions') }}
where quality_status = 'accepted'
