select
    event_date,
    traffic_source,
    traffic_medium,
    device_category,
    country,
    count(*) as row_count

from {{ ref('fct_daily_performance') }}

group by
    event_date,
    traffic_source,
    traffic_medium,
    device_category,
    country

having count(*) > 1