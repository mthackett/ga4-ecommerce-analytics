with funnel as (

    select *
    from {{ ref('fct_funnel_performance') }}

),

step_progression as (

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        'View → Cart' as funnel_step,
        1 as step_order,

        view_item_sessions as starting_sessions,
        view_to_cart_sessions as progressed_sessions

    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        'Cart → Checkout',
        2,

        add_to_cart_sessions,
        cart_to_checkout_sessions

    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        'Checkout → Shipping',
        3,

        begin_checkout_sessions,
        checkout_to_shipping_sessions

    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        'Shipping → Payment',
        4,

        shipping_sessions,
        shipping_to_payment_sessions

    from funnel

    union all

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        'Payment → Purchase',
        5,

        payment_sessions,
        payment_to_purchase_sessions

    from funnel

)

select *
from step_progression