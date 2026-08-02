{{ config(
    materialized = 'view'
) }}

with source_item_events as (

    select
        parse_date('%Y%m%d', events.event_date) as event_date,
        timestamp_micros(events.event_timestamp) as event_timestamp,
        events.event_name,
        events.user_pseudo_id,

        (
            select value.int_value
            from unnest(events.event_params)
            where key = 'ga_session_id'
        ) as ga_session_id,

        events.ecommerce.transaction_id,

        concat(
            events.user_pseudo_id,
            '-',
            cast(events.event_timestamp as string),
            '-',
            events.event_name
        ) as event_key,

        item_index,

        item.item_id,
        item.item_name,
        item.item_brand,
        item.item_variant,

        item.item_category,
        item.item_category2,
        item.item_category3,
        item.item_category4,
        item.item_category5,

        item.price,
        item.quantity,
        item.item_revenue,

        item.item_list_id,
        item.item_list_name,
        item.item_list_index,

        item.promotion_id,
        item.promotion_name,
        item.creative_name,
        item.creative_slot

    from
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` as events

    cross join unnest(events.items) as item
        with offset as item_index

    where events._table_suffix between
        replace('{{ var("dev_start_date") }}', '-', '')
        and replace('{{ var("dev_end_date") }}', '-', '')

)

select
    concat(
        event_key,
        '-',
        cast(item_index as string)
    ) as event_item_key,

    *

from source_item_events