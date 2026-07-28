select
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country,

    count(*) as total_sessions,
    count(distinct user_pseudo_id) as users,

    countif(has_view_item)
        as view_item_sessions,

    countif(has_add_to_cart)
        as add_to_cart_sessions,

    countif(has_begin_checkout)
        as begin_checkout_sessions,

    countif(has_add_shipping_info)
        as shipping_sessions,

    countif(has_add_payment_info)
        as payment_sessions,

    countif(has_valid_purchase)
        as valid_purchase_sessions,

    count(distinct case
        when has_valid_purchase
        then user_pseudo_id
    end) as purchasers,

    countif(reached_ordered_cart)
        as ordered_cart_sessions,

    countif(reached_ordered_checkout)
        as ordered_checkout_sessions,

    countif(reached_ordered_shipping)
        as ordered_shipping_sessions,

    countif(reached_ordered_payment)
        as ordered_payment_sessions,

    countif(completed_ordered_funnel)
        as completed_ordered_funnel_sessions,

    countif(progressed_view_to_cart)
        as view_to_cart_sessions,

    countif(progressed_cart_to_checkout)
        as cart_to_checkout_sessions,

    countif(progressed_checkout_to_shipping)
        as checkout_to_shipping_sessions,

    countif(progressed_shipping_to_payment)
        as shipping_to_payment_sessions,

    countif(progressed_payment_to_purchase)
        as payment_to_purchase_sessions,

    sum(transactions) as transactions,
    sum(purchase_revenue) as purchase_revenue

from {{ ref('int_ga4__session_funnel') }}

group by
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country