with product_revenue as (

    select
        sum(item_revenue) as item_revenue

    from {{ ref('fct_product_performance') }}

),

transaction_revenue as (

    select
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('int_ga4__transactions') }}

),

reconciliation as (

    select
        product_revenue.item_revenue,
        transaction_revenue.purchase_revenue,

        product_revenue.item_revenue
            - transaction_revenue.purchase_revenue
            as revenue_difference,

        safe_divide(
            abs(
                product_revenue.item_revenue
                    - transaction_revenue.purchase_revenue
            ),
            abs(transaction_revenue.purchase_revenue)
        ) as relative_difference

    from product_revenue
    cross join transaction_revenue

)

select *

from reconciliation

where relative_difference > 0.001