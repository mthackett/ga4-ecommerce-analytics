select
    event_date,
    timestamp_micros(event_timestamp) as event_timestamp,
    event_name,
    user_pseudo_id,
    user_first_touch_timestamp,
    --is_active_user,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'is_active_user') as is_active_user,
    platform,

    -- session/event params
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_number') as ga_session_number,
    (select value.string_value from unnest(event_params) where key = 'page_location') as page_location,
    (select value.string_value from unnest(event_params) where key = 'page_title') as page_title,
    (select value.string_value from unnest(event_params) where key = 'page_referrer') as page_referrer,
    (select value.int_value from unnest(event_params) where key = 'engagement_time_msec') as engagement_time_msec,
    (select value.string_value from unnest(event_params) where key = 'session_engaged') as session_engaged,

    -- traffic source
    traffic_source.source as traffic_source,
    traffic_source.medium as traffic_medium,
    traffic_source.name as traffic_campaign,

    -- device
    device.category as device_category,
    device.operating_system as operating_system,
    device.language as device_language,
    device.web_info.browser as browser,

    -- geo
    geo.country as country,
    geo.region as region,
    geo.city as city,

    -- ecommerce event-level fields
    ecommerce.transaction_id,
    ecommerce.purchase_revenue,
    ecommerce.total_item_quantity,
    ecommerce.unique_items,

    -- stable event key for downstream joins
    concat(
        user_pseudo_id,
        '-',
        cast(event_timestamp as string),
        '-',
        event_name
    ) as event_key


from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

--where _table_suffix between '{{ var("start_date", "20201127") }}' and '{{ var("end_date", "20201130") }}'
where _table_suffix between
    replace('{{ var("dev_start_date") }}', '-', '')
    and replace('{{ var("dev_end_date") }}', '-', '')