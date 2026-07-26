select
    cast(event_id as varchar) as event_id,
    cast(event_time as timestamp_ntz) as snapshot_at,
    cast(warehouse_id as varchar) as warehouse_id,
    cast(product_id as varchar) as product_id,
    cast(on_hand_quantity as number(18, 4)) as on_hand_quantity,
    cast(reserved_quantity as number(18, 4)) as reserved_quantity,
    cast(processed_at as timestamp_ntz) as processed_at
from {{ source('raw', 'inventory_snapshots') }}
where quality_status = 'accepted'
