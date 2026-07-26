select
    product_id,
    sku,
    category,
    unit_price,
    active,
    processed_at as effective_at
from {{ ref('stg_product_catalog') }}
