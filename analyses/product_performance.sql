with product_summary as (
    select
        product_key,
        -- choose one display name variant associated with each product_key
        any_value(product_name) as product_name,

        sum(product_view_events) as product_view_events,
        sum(add_to_cart_events) as add_to_cart_events,
        sum(begin_checkout_events) as begin_checkout_events,
        sum(product_transactions) as product_transactions,
        sum(units_purchased) as units_purchased,
        sum(item_revenue) as item_revenue

    from {{ ref('fct_product_performance') }}

    group by product_key

),

product_performance as (

    select 
        product_key,
        product_name,
        product_view_events,
        add_to_cart_events,
        begin_checkout_events,
        product_transactions,
        units_purchased,
        item_revenue,

                safe_divide(
            add_to_cart_events,
            product_view_events
        ) as cart_events_per_view_event_raw,

        safe_divide(
            product_transactions,
            product_view_events
        ) as transactions_per_view_event_raw,

        safe_divide(
            item_revenue,
            product_view_events
        ) as revenue_per_view_event_raw,

        safe_divide(
            item_revenue,
            sum(item_revenue) over ()
        ) as revenue_share_raw

    from product_summary

)

select
    product_key,
    product_name,
    product_view_events,
    add_to_cart_events,
    begin_checkout_events,
    product_transactions,
    units_purchased,
    item_revenue,

    round(
        cart_events_per_view_event_raw,
        4
    ) as cart_events_per_view_event,

    round(
        transactions_per_view_event_raw,
        4
    ) as transactions_per_view_event,

    round(
        revenue_per_view_event_raw,
        2
    ) as revenue_per_view_event,

    round(
        100 * revenue_share_raw,
        2
    ) as revenue_share_pct,

    case
        when product_view_events = 0
            and product_transactions > 0
            then 'purchases_without_recorded_views'

        when product_view_events >= 10000
            and revenue_per_view_event_raw < 0.20
            then 'high_interest_low_value'

        when product_view_events < 5000
            and revenue_per_view_event_raw >= 1.00
            then 'low_volume_high_value'

        else 'standard'
    end as performance_segment

from product_performance

order by item_revenue desc

