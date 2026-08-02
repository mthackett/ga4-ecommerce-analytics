with event_metrics as (

    select
        event_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        count(*) as event_count,

        count(distinct user_pseudo_id) as users,

        count(distinct case
            when ga_session_id is not null
            then concat(
                user_pseudo_id,
                '-',
                cast(ga_session_id as string)
            )
        end) as sessions,

        countif(event_name = 'purchase') as purchase_events

    from {{ ref('stg_ga4__events') }}

    group by
        event_date,
        traffic_source,
        traffic_medium,
        device_category,
        country

),

transaction_metrics as (

    select
        transaction_date as event_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        count(*) as transactions,
        count(distinct user_pseudo_id) as purchasers,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('int_ga4__transactions') }}

    group by
        transaction_date,
        traffic_source,
        traffic_medium,
        device_category,
        country

)

select
    events.event_date,
    events.traffic_source,
    events.traffic_medium,
    events.device_category,
    events.country,
    events.event_count,
    events.users,
    events.sessions,
    events.purchase_events,
    coalesce(transactions.purchasers, 0) as purchasers,
    coalesce(transactions.transactions, 0) as transactions,
    coalesce(transactions.purchase_revenue, 0) as purchase_revenue

from event_metrics as events

left join transaction_metrics as transactions
    on events.event_date = transactions.event_date
    and events.traffic_source
        is not distinct from transactions.traffic_source
    and events.traffic_medium
        is not distinct from transactions.traffic_medium
    and events.device_category
        is not distinct from transactions.device_category
    and events.country
        is not distinct from transactions.country