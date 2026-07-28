with session_events as (

    select
        concat(
            user_pseudo_id,
            '-',
            cast(ga_session_id as string)
        ) as session_key,

        user_pseudo_id,
        ga_session_id,

        min(event_date) as session_date,
        min(event_timestamp) as session_started_at,
        max(event_timestamp) as session_ended_at,

        array_agg(
            traffic_source ignore nulls
            order by event_timestamp
            limit 1
        )[safe_offset(0)] as traffic_source,

        array_agg(
            traffic_medium ignore nulls
            order by event_timestamp
            limit 1
        )[safe_offset(0)] as traffic_medium,

        array_agg(
            device_category ignore nulls
            order by event_timestamp
            limit 1
        )[safe_offset(0)] as device_category,

        array_agg(
            country ignore nulls
            order by event_timestamp
            limit 1
        )[safe_offset(0)] as country,

        min(case
            when event_name = 'view_item'
            then event_timestamp
        end) as first_view_item_at,

        min(case
            when event_name = 'add_to_cart'
            then event_timestamp
        end) as first_add_to_cart_at,

        min(case
            when event_name = 'begin_checkout'
            then event_timestamp
        end) as first_begin_checkout_at,

        min(case
            when event_name = 'add_shipping_info'
            then event_timestamp
        end) as first_add_shipping_info_at,

        min(case
            when event_name = 'add_payment_info'
            then event_timestamp
        end) as first_add_payment_info_at

    from {{ ref('stg_ga4__events') }}

    where user_pseudo_id is not null
      and ga_session_id is not null

    group by
        user_pseudo_id,
        ga_session_id

),

session_transactions as (

    select
        session_key,

        min(transaction_timestamp) as first_valid_purchase_at,
        count(*) as transactions,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('int_ga4__transactions') }}

    group by session_key

),

combined as (

    select
        sessions.*,

        transactions.first_valid_purchase_at,

        coalesce(
            transactions.transactions,
            0
        ) as transactions,

        coalesce(
            transactions.purchase_revenue,
            0
        ) as purchase_revenue

    from session_events as sessions

    left join session_transactions as transactions
        using (session_key)

)

select
    session_key,
    user_pseudo_id,
    ga_session_id,

    session_date,
    session_started_at,
    session_ended_at,

    traffic_source,
    traffic_medium,
    device_category,
    country,

    first_view_item_at,
    first_add_to_cart_at,
    first_begin_checkout_at,
    first_add_shipping_info_at,
    first_add_payment_info_at,
    first_valid_purchase_at,

    first_view_item_at is not null
        as has_view_item,

    first_add_to_cart_at is not null
        as has_add_to_cart,

    first_begin_checkout_at is not null
        as has_begin_checkout,

    first_add_shipping_info_at is not null
        as has_add_shipping_info,

    first_add_payment_info_at is not null
        as has_add_payment_info,

    first_valid_purchase_at is not null
        as has_valid_purchase,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        as reached_ordered_cart,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        and first_begin_checkout_at >= first_add_to_cart_at
        as reached_ordered_checkout,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        and first_begin_checkout_at >= first_add_to_cart_at
        and first_add_shipping_info_at >= first_begin_checkout_at
        as reached_ordered_shipping,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        and first_begin_checkout_at >= first_add_to_cart_at
        and first_add_shipping_info_at >= first_begin_checkout_at
        and first_add_payment_info_at >= first_add_shipping_info_at
        as reached_ordered_payment,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        and first_begin_checkout_at >= first_add_to_cart_at
        and first_add_shipping_info_at >= first_begin_checkout_at
        and first_add_payment_info_at >= first_add_shipping_info_at
        and first_valid_purchase_at >= first_add_payment_info_at
        as completed_ordered_funnel,

    first_view_item_at is not null
        and first_add_to_cart_at >= first_view_item_at
        as progressed_view_to_cart,

    first_add_to_cart_at is not null
        and first_begin_checkout_at >= first_add_to_cart_at
        as progressed_cart_to_checkout,

    first_begin_checkout_at is not null
        and first_add_shipping_info_at >= first_begin_checkout_at
        as progressed_checkout_to_shipping,

    first_add_shipping_info_at is not null
        and first_add_payment_info_at >= first_add_shipping_info_at
        as progressed_shipping_to_payment,

    first_add_payment_info_at is not null
        and first_valid_purchase_at >= first_add_payment_info_at
        as progressed_payment_to_purchase,
        
    transactions,
    purchase_revenue

from combined