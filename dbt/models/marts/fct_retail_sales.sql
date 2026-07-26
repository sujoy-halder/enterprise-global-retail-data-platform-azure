with store_sales as (
    select
        event_id,
        sold_at as sales_at,
        cast(sold_at as date) as sales_date,
        store_id,
        null as order_id,
        product_id,
        quantity,
        gross_amount,
        currency,
        'store' as sales_channel
    from {{ ref('stg_pos_transactions') }}
),
online_sales as (
    select
        event_id,
        ordered_at as sales_at,
        cast(ordered_at as date) as sales_date,
        null as store_id,
        order_id,
        product_id,
        quantity,
        gross_amount,
        'USD' as currency,
        'online' as sales_channel
    from {{ ref('stg_online_orders') }}
    where order_status in ('paid', 'shipped')
)
select * from store_sales
union all
select * from online_sales
