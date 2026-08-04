with cpc_performance as (
    select
        sum(total_sessions) as total_sessions,
        sum(valid_purchase_sessions) as purchase_sessions,
        sum(transactions) as transactions,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('fct_funnel_performance') }}

    where traffic_source = 'google'
        and traffic_medium = 'cpc'

),

roas_scenarios as (
    select 2.0 as target_roas
    union all
    select 3.0
    union all
    select 4.0

)

select
    target_roas,

    total_sessions,
    purchase_sessions,
    transactions,
    purchase_revenue,

    round(
        safe_divide(
            purchase_revenue,
            target_roas
        ),
        2
    ) as maximum_allowable_ad_spend,

    round(
        safe_divide(
            safe_divide(
                purchase_revenue,
                target_roas
            ),
            total_sessions
        ),
        2
    ) as maximum_cost_per_session,

    round(
        safe_divide(
            safe_divide(
                purchase_revenue,
                target_roas
            ),
            transactions
        ),
        2
    ) as maximum_cost_per_transaction

from cpc_performance
cross join roas_scenarios