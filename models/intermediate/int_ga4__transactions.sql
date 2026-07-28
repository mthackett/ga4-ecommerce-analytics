with valid_purchase_events as (

    select
        event_key,
        event_date,
        event_timestamp,
        user_pseudo_id,
        transaction_id,
        traffic_source,
        traffic_medium,
        device_category,
        country,
        purchase_revenue

    from {{ ref('stg_ga4__events') }}

    where event_name = 'purchase'
      and transaction_id is not null
      and trim(transaction_id) != ''
      and lower(trim(transaction_id)) != '(not set)'

),

deduplicated_transactions as (

    select *

    from valid_purchase_events

    qualify row_number() over (
        partition by transaction_id
        order by event_timestamp, event_key
    ) = 1

)

select
    event_date,
    event_timestamp as transaction_timestamp,
    user_pseudo_id,
    transaction_id,
    traffic_source,
    traffic_medium,
    device_category,
    country,
    coalesce(purchase_revenue, 0) as purchase_revenue

from deduplicated_transactions