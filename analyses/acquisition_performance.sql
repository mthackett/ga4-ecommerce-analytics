with acquisition as (
    select
        traffic_source,
        traffic_medium,

        sum(total_sessions) as total_sessions,
        sum(valid_purchase_sessions) as purchase_sessions,
        sum(transactions) as transactions,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('fct_funnel_performance') }}

    group by traffic_source, traffic_medium

)

select
    traffic_source,
    traffic_medium,
    total_sessions,
    purchase_sessions,
    transactions,
    purchase_revenue,

    round(
        100 * safe_divide(
            purchase_sessions,
            total_sessions
    ),
    2
    ) as session_conversion_rate_pct,

    round(
        safe_divide(
            transactions,
            total_sessions
        ),
        4
    ) as transactions_per_session,

    round(
        safe_divide(
            purchase_revenue,
            transactions
        ),
        2
    ) as average_order_value,

    round(
        safe_divide(
            purchase_revenue,
            total_sessions
        ),
        2
    ) as revenue_per_session,

    round(
        100 * safe_divide(
            purchase_revenue,
            sum(purchase_revenue) over ()
        ),
        2
    ) as revenue_share_pct

from acquisition

order by purchase_revenue desc