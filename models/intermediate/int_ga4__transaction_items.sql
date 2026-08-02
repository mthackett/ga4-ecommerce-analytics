{{ config(
    materialized = 'view'
) }}

select
    concat(
        transactions.transaction_id,
        '-',
        cast(items.item_index as string)
    ) as transaction_item_key,

    transactions.transaction_id,
    transactions.purchase_event_key,
    transactions.transaction_timestamp,
    date(transactions.transaction_timestamp) as purchase_date,

    items.item_index,
    items.item_id,
    items.item_name,
    items.item_brand,
    items.item_variant,

    items.item_category,
    items.item_category2,
    items.item_category3,
    items.item_category4,
    items.item_category5,

    items.price,
    items.quantity,
    items.item_revenue,

    items.item_list_id,
    items.item_list_name,
    items.item_list_index

from {{ ref('int_ga4__transactions') }} as transactions

inner join {{ ref('stg_ga4__event_items') }} as items
    on transactions.purchase_event_key = items.event_key
    and items.event_name = 'purchase'