with performance as (
    select
        min(session_date) as first_date,
        max(session_date) as last_date,
        sum(total_sessions) as total_sessions,
        sum(transactions) as transactions,
        sum(purchase_revenue) as purchase_revenue,
        sum(valid_purchase_sessions) as purchase_sessions

    from {{ ref('fct_funnel_performance') }}
),

people as (
    select 
        count(distinct user_pseudo_id) as users,
        count(distinct case
            when transactions > 0 then user_pseudo_id
        end) as purchasers

    from {{ ref('int_ga4__session_funnel')}}
)

select
    performance.first_date,
    performance.last_date,
    people.users,
    performance.total_sessions,
    people.purchasers,
    performance.transactions,
    performance.purchase_revenue,

    safe_divide(
        performance.transactions,
        performance.total_sessions
    ) as transactions_per_session,

    safe_divide(
        performance.purchase_sessions,
        performance.total_sessions
    ) as session_conversion_rate,

    safe_divide(
        people.purchasers,
        people.users
    ) as purchase_rate,

    safe_divide(
        purchase_revenue,
        transactions
        ) as average_order_value,

    safe_divide(
        performance.purchase_revenue,
        performance.total_sessions
    ) as revenue_per_session

from performance cross join people