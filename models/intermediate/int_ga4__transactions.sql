with valid_purchase_events as (

    select
        event_key,
        event_date,
        event_timestamp,

        user_pseudo_id,
        ga_session_id,

        concat(
            user_pseudo_id,
            '-',
            cast(ga_session_id as string)
        ) as session_key,

        transaction_id,

        traffic_source,
        traffic_medium,
        traffic_campaign,

        platform,
        device_category,

        country,
        region,
        city,

        purchase_revenue,
        total_item_quantity,
        unique_items

    from {{ ref('stg_ga4__events') }}

    where event_name = 'purchase'
      and transaction_id is not null
      and trim(transaction_id) != ''
      and lower(trim(transaction_id)) != '(not set)'

),

deduplicated_transactions as (
    -- Select only the first valid transaction ID
    
    select *

    from valid_purchase_events

    qualify row_number() over (
        partition by transaction_id
        order by event_timestamp, event_key
    ) = 1

)

select
    transaction_id,

    event_date as transaction_date,
    event_timestamp as transaction_timestamp,

    user_pseudo_id,
    ga_session_id,
    session_key,

    traffic_source,
    traffic_medium,
    traffic_campaign,

    platform,
    device_category,

    country,
    region,
    city,

    coalesce(purchase_revenue, 0) as purchase_revenue,
    coalesce(total_item_quantity, 0) as total_item_quantity,
    coalesce(unique_items, 0) as unique_items

from deduplicated_transactions