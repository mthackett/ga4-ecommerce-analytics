with funnel as (
    select
        device_category,

        sum(total_sessions) as total_sessions,
        sum(view_item_sessions) as view_item_sessions,
        sum(add_to_cart_sessions) as add_to_cart_sessions,
        sum(begin_checkout_sessions) as begin_checkout_sessions,
        sum(payment_sessions) as payment_sessions,
        sum(valid_purchase_sessions) as purchase_sessions,

        sum(transactions) as transactions,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('fct_funnel_performance' )}}

    group by device_category

)

select
    device_category,

    total_sessions,
    view_item_sessions,
    add_to_cart_sessions,
    begin_checkout_sessions,
    payment_sessions,
    purchase_sessions,

    transactions,
    purchase_revenue,

    round(
        100 * safe_divide(
            add_to_cart_sessions,
            view_item_sessions
        ),
        2
    ) as view_to_cart_rate_pct,

    round(
        100 * safe_divide(
            begin_checkout_sessions,
            add_to_cart_sessions
        ),
        2
    ) as cart_to_checkout_rate_pct,

    round(
        100 * safe_divide(
            payment_sessions,
            begin_checkout_sessions
        ),
        2
    ) as checkout_to_payment_rate_pct,

    round(
        100 * safe_divide(
            purchase_sessions,
            payment_sessions
        ),
        2
    ) as payment_to_purchase_rate_pct,

    round(
        safe_divide(
            purchase_revenue,
            total_sessions
        ),
        2
    ) as revenue_per_session,

    round(
        100 * safe_divide(
            purchase_sessions,
            total_sessions
        ),
        2
    ) as session_conversion_rate_pct

from funnel

order by purchase_revenue desc