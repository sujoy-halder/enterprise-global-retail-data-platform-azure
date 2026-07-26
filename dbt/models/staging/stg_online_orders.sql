select
    cast(event_id as varchar) as event_id,
    cast(event_time as timestamp_ntz) as ordered_at,
    cast(order_id as varchar) as order_id,
    cast(product_id as varchar) as product_id,
    cast(quantity as number(18, 4)) as quantity,
    cast(gross_amount as number(18, 4)) as gross_amount,
    cast(order_status as varchar) as order_status,
    cast(processed_at as timestamp_ntz) as processed_at
from {{ source('raw', 'online_orders') }}
where quality_status = 'accepted'
