select *

from {{ ref('fct_funnel_performance') }}

where total_sessions < 0
    or users < 0
    or view_item_sessions < 0
    or add_to_cart_sessions < 0
    or begin_checkout_sessions < 0
    or shipping_sessions < 0
    or payment_sessions < 0
    or valid_purchase_sessions < 0
    or purchasers < 0
    or transactions < 0
    or purchase_revenue < 0

    or view_item_sessions > total_sessions
    or add_to_cart_sessions > total_sessions
    or begin_checkout_sessions > total_sessions
    or shipping_sessions > total_sessions
    or payment_sessions > total_sessions
    or valid_purchase_sessions > total_sessions

    or purchasers > valid_purchase_sessions
    or transactions < valid_purchase_sessions

    or ordered_cart_sessions > view_item_sessions
    or ordered_checkout_sessions > ordered_cart_sessions
    or ordered_shipping_sessions > ordered_checkout_sessions
    or ordered_payment_sessions > ordered_shipping_sessions
    or completed_ordered_funnel_sessions > ordered_payment_sessions

    or view_to_cart_sessions > view_item_sessions
    or cart_to_checkout_sessions > add_to_cart_sessions
    or checkout_to_shipping_sessions > begin_checkout_sessions
    or shipping_to_payment_sessions > shipping_sessions
    or payment_to_purchase_sessions > payment_sessions