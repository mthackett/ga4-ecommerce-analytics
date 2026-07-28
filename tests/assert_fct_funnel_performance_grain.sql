select
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country,
    count(*) as row_count

from {{ ref('fct_funnel_performance') }}

group by
    session_date,
    traffic_source,
    traffic_medium,
    device_category,
    country

having count(*) > 1