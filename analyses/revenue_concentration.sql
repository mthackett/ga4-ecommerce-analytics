with product_revenue as (

    select
        product_key,
        max(product_name) as product_name,

        sum(item_revenue) as item_revenue,
        sum(units_purchased) as units_purchased

    from {{ ref('fct_product_performance') }}

    where item_revenue > 0

    group by 1

),

ranked_products as (

    select
        product_key,
        product_name,
        item_revenue,
        units_purchased,

        row_number() over (
            order by item_revenue desc
        ) as product_rank,

        sum(item_revenue) over () as total_revenue

    from product_revenue

),

revenue_shares as (

    select
        *,

        safe_divide(
            item_revenue,
            total_revenue
        ) as revenue_share_raw,

        safe_divide(
            sum(item_revenue) over (
                order by item_revenue desc
                rows between unbounded preceding and current row
            ),
            total_revenue
        ) as cumulative_revenue_share_raw

    from ranked_products

),

threshold_summary as (

    select
        min(
            case
                when cumulative_revenue_share_raw >= 0.50
                    then product_rank
            end
        ) as products_to_reach_50_pct_revenue,

        min(
            case
                when cumulative_revenue_share_raw >= 0.80
                    then product_rank
            end
        ) as products_to_reach_80_pct_revenue,

        max(product_rank) as revenue_generating_products,

        max(total_revenue) as total_revenue

    from revenue_shares

),

classified_products as (

    select
        revenue_shares.*,

        threshold_summary.products_to_reach_50_pct_revenue,
        threshold_summary.products_to_reach_80_pct_revenue,
        threshold_summary.revenue_generating_products,
        threshold_summary.total_revenue as summary_total_revenue,

        case
            when product_rank
                <= threshold_summary.products_to_reach_50_pct_revenue
                then 'top_50_pct_revenue'

            when product_rank
                <= threshold_summary.products_to_reach_80_pct_revenue
                then 'next_30_pct_revenue'

            else 'remaining_20_pct_revenue'
        end as revenue_concentration_band

    from revenue_shares
    cross join threshold_summary

),

summary_metrics as (

    select
        products_to_reach_50_pct_revenue,
        products_to_reach_80_pct_revenue,
        revenue_generating_products,
        summary_total_revenue as total_revenue,

        safe_divide(
            products_to_reach_50_pct_revenue,
            revenue_generating_products
        ) as share_of_products_to_reach_50_pct_raw,

        safe_divide(
            products_to_reach_80_pct_revenue,
            revenue_generating_products
        ) as share_of_products_to_reach_80_pct_raw,

        max(
            case
                when product_rank = 1
                    then revenue_share_raw
            end
        ) as top_1_product_revenue_share_raw,

        sum(
            case
                when product_rank <= 5
                    then revenue_share_raw
                else 0
            end
        ) as top_5_product_revenue_share_raw,

        sum(
            case
                when product_rank <= 10
                    then revenue_share_raw
                else 0
            end
        ) as top_10_product_revenue_share_raw

    from classified_products

    group by
        products_to_reach_50_pct_revenue,
        products_to_reach_80_pct_revenue,
        revenue_generating_products,
        summary_total_revenue

),

final_analysis as (

    select
        product_rank,
        product_key,
        product_name,

        round(
            item_revenue,
            2
        ) as item_revenue,

        units_purchased,

        round(
            100 * revenue_share_raw,
            2
        ) as revenue_share_pct,

        round(
            100 * cumulative_revenue_share_raw,
            2
        ) as cumulative_revenue_share_pct,

        revenue_concentration_band

    from classified_products

)

select *
from final_analysis

order by product_rank

/*
select
    round(total_revenue, 2) as total_revenue,
    revenue_generating_products,

    products_to_reach_50_pct_revenue,

    round(
        100 * share_of_products_to_reach_50_pct_raw,
        2
    ) as share_of_products_to_reach_50_pct,

    products_to_reach_80_pct_revenue,

    round(
        100 * share_of_products_to_reach_80_pct_raw,
        2
    ) as share_of_products_to_reach_80_pct,

    round(
        100 * top_1_product_revenue_share_raw,
        2
    ) as top_1_product_revenue_share_pct,

    round(
        100 * top_5_product_revenue_share_raw,
        2
    ) as top_5_product_revenue_share_pct,

    round(
        100 * top_10_product_revenue_share_raw,
        2
    ) as top_10_product_revenue_share_pct

from summary_metrics

*/