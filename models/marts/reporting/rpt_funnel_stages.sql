with funnel as (

    select *
    from {{ ref('fct_funnel_performance') }}

),

stage_reach as (

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        funnel_stage,
        stage_sessions

    from funnel

    unpivot (
        stage_sessions for funnel_stage in (
            view_item_sessions as 'Product View',
            add_to_cart_sessions as 'Add to Cart',
            begin_checkout_sessions as 'Begin Checkout',
            shipping_sessions as 'Shipping Info',
            payment_sessions as 'Payment Info',
            valid_purchase_sessions as 'Purchase'
        )
    )

)

select
    *,
    case funnel_stage
        when 'Product View' then 1
        when 'Add to Cart' then 2
        when 'Begin Checkout' then 3
        when 'Shipping Info' then 4
        when 'Payment Info' then 5
        when 'Purchase' then 6
    end as stage_order

from stage_reach