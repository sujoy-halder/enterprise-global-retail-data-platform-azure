select
    cast(product_id as varchar) as product_id,
    cast(sku as varchar) as sku,
    cast(category as varchar) as category,
    cast(unit_price as number(18, 4)) as unit_price,
    cast(active as boolean) as active,
    cast(processed_at as timestamp_ntz) as processed_at
from {{ source('raw', 'product_catalog') }}
where quality_status = 'accepted'
qualify row_number() over (partition by product_id order by processed_at desc) = 1
