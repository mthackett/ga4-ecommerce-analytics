with funnel as (

    select *
    from {{ ref('fct_funnel_performance') }}

),

ordered_stages as (

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Product View' as funnel_stage,
        1 as stage_order,
        view_item_sessions as stage_sessions
    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Add to Cart',
        2,
        ordered_cart_sessions
    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Begin Checkout',
        3,
        ordered_checkout_sessions
    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Shipping Info',
        4,
        ordered_shipping_sessions
    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Payment Info',
        5,
        ordered_payment_sessions
    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        'Purchase',
        6,
        completed_ordered_funnel_sessions
    from funnel

)

select *
from ordered_stages