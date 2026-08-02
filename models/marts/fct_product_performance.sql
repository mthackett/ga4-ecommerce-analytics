{{ config(
    materialized = 'table'
) }}

with valid_product_events as (

    select
        items.event_date,
        items.event_key,
        items.event_name,

        lower(
            regexp_replace(
                trim(items.item_name),
                r'\s+',
                ' '
            )
        ) as product_key,

        items.item_name as product_name,
        items.item_id,
        items.quantity,
        items.item_revenue,

        transactions.transaction_id as valid_transaction_id

    from {{ ref('stg_ga4__event_items') }} as items

    left join {{ ref('int_ga4__transactions') }} as transactions
        on items.event_key = transactions.purchase_event_key

    where items.event_name in (
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )

      and items.item_name is not null
      and trim(items.item_name) != ''
      and items.item_name != '(not set)'

      -- Only canonical, transaction-backed purchase events are retained.
      and (
          items.event_name != 'purchase'
          or transactions.transaction_id is not null
      )

),

product_daily_metrics as (

    select
        event_date,
        product_key,
        max(product_name) as product_name,

        count(distinct item_id) as observed_item_ids,

        count(distinct if(
            event_name = 'view_item',
            event_key,
            null
        )) as product_view_events,

        count(distinct if(
            event_name = 'add_to_cart',
            event_key,
            null
        )) as add_to_cart_events,

        count(distinct if(
            event_name = 'begin_checkout',
            event_key,
            null
        )) as begin_checkout_events,

        count(distinct if(
            event_name = 'purchase',
            valid_transaction_id,
            null
        )) as product_transactions,

        sum(if(
            event_name = 'purchase',
            coalesce(quantity, 0),
            0
        )) as units_purchased,

        round(sum(if(
            event_name = 'purchase',
            coalesce(item_revenue, 0),
            0
        )), 2) as item_revenue

    from valid_product_events

    group by
        event_date,
        product_key

)

select
    concat(
        cast(event_date as string),
        '|',
        product_key
    ) as product_performance_key,

    *,

    safe_divide(
        add_to_cart_events,
        product_view_events
    ) as cart_events_per_view_event,

    safe_divide(
        product_transactions,
        product_view_events
    ) as transactions_per_view_event,

    safe_divide(
        item_revenue,
        product_view_events
    ) as revenue_per_view_event

from product_daily_metrics