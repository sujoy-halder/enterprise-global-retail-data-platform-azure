select
    snapshot_at,
    cast(snapshot_at as date) as snapshot_date,
    warehouse_id,
    product_id,
    on_hand_quantity,
    reserved_quantity,
    on_hand_quantity - reserved_quantity as available_quantity
from {{ ref('stg_inventory_snapshots') }}
