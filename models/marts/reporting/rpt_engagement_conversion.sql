with sessions as (

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        engagement_time_seconds,
        has_valid_purchase,
        purchase_revenue

    from {{ ref('int_ga4__session_funnel') }}

),

engagement_bands as (

    select
        session_date,
        traffic_source,
        traffic_medium,
        device_category,
        country,

        case
            when engagement_time_seconds <= 10 then '0–10 sec'
            when engagement_time_seconds <= 30 then '10–30 sec'
            when engagement_time_seconds <= 60 then '30–60 sec'
            when engagement_time_seconds <= 180 then '1–3 min'
            when engagement_time_seconds <= 600 then '3–10 min'
            else '10+ min'
        end as engagement_band,

        case
            when engagement_time_seconds <= 10 then 1
            when engagement_time_seconds <= 30 then 2
            when engagement_time_seconds <= 60 then 3
            when engagement_time_seconds <= 180 then 4
            when engagement_time_seconds <= 600 then 5
            else 6
        end as band_order,

        has_valid_purchase,
        purchase_revenue

    from sessions

)

select
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country,

    engagement_band,
    band_order,

    count(*) as sessions,
    countif(has_valid_purchase) as purchase_sessions,
    sum(purchase_revenue) as purchase_revenue

from engagement_bands

group by
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country,
    engagement_band,
    band_order