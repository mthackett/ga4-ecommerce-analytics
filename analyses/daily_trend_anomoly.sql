with parameters as (

    select
        2.0 as anomaly_z_threshold,

        -- Attention thresholds
        1.25 as attention_spike_ratio_threshold,
        0.75 as attention_drop_ratio_threshold,

        -- Monetization thresholds
        1000.0 as positive_revenue_impact_threshold,
        -750.0 as negative_revenue_impact_threshold,
        1.50 as strong_revenue_spike_ratio_threshold,
        0.50 as strong_revenue_drop_ratio_threshold,

        -- Efficiency thresholds
        1.25 as efficiency_spike_ratio_threshold,
        0.75 as efficiency_drop_ratio_threshold

),

daily_performance as (

    select
        parse_date('%Y%m%d', session_date) as session_date,

        sum(total_sessions) as total_sessions,
        sum(valid_purchase_sessions) as purchase_sessions,
        sum(transactions) as transactions,
        sum(purchase_revenue) as purchase_revenue

    from {{ ref('fct_funnel_performance') }}

    group by 1

),

daily_metrics as (

    select
        session_date,
        total_sessions,
        purchase_sessions,
        transactions,
        purchase_revenue,

        safe_divide(
            purchase_sessions,
            total_sessions
        ) as session_conversion_rate_raw,

        safe_divide(
            purchase_revenue,
            transactions
        ) as average_order_value_raw,

        safe_divide(
            purchase_revenue,
            total_sessions
        ) as revenue_per_session_raw

    from daily_performance

),

rolling_metrics as (

    select
        *,

        -- Require a complete prior 14-day window before
        -- evaluating anomaly classifications.
        count(*) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_observations,

        --------------------------------------------------
        -- ATTENTION: SESSIONS
        --------------------------------------------------

        avg(total_sessions) over (
            order by session_date
            rows between 6 preceding and current row
        ) as sessions_7_day_sma,

        avg(total_sessions) over (
            order by session_date
            rows between 13 preceding and current row
        ) as sessions_14_day_sma,

        avg(total_sessions) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_sessions,

        stddev_samp(total_sessions) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_sessions,

        --------------------------------------------------
        -- MONETIZATION: REVENUE
        --------------------------------------------------

        avg(purchase_revenue) over (
            order by session_date
            rows between 6 preceding and current row
        ) as revenue_7_day_sma,

        avg(purchase_revenue) over (
            order by session_date
            rows between 13 preceding and current row
        ) as revenue_14_day_sma,

        avg(purchase_revenue) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_revenue,

        stddev_samp(purchase_revenue) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_revenue,

        --------------------------------------------------
        -- MONETIZATION CONFIRMATION: TRANSACTIONS
        --------------------------------------------------

        avg(transactions) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_transactions,

        stddev_samp(transactions) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_transactions,

        --------------------------------------------------
        -- EFFICIENCY: REVENUE PER SESSION
        --------------------------------------------------

        avg(revenue_per_session_raw) over (
            order by session_date
            rows between 6 preceding and current row
        ) as revenue_per_session_7_day_sma,

        avg(revenue_per_session_raw) over (
            order by session_date
            rows between 13 preceding and current row
        ) as revenue_per_session_14_day_sma,

        avg(revenue_per_session_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_revenue_per_session,

        stddev_samp(revenue_per_session_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_revenue_per_session,

        --------------------------------------------------
        -- EFFICIENCY DIAGNOSTICS
        --------------------------------------------------

        avg(session_conversion_rate_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_conversion_rate,

        stddev_samp(session_conversion_rate_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_conversion_rate,

        avg(average_order_value_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_avg_aov,

        stddev_samp(average_order_value_raw) over (
            order by session_date
            rows between 14 preceding and 1 preceding
        ) as prior_14_day_stddev_aov

    from daily_metrics

),

comparison_metrics as (

    select
        *,

        --------------------------------------------------
        -- TREND RATIOS
        --------------------------------------------------

        safe_divide(
            sessions_7_day_sma,
            sessions_14_day_sma
        ) as sessions_7_day_vs_14_day_sma_raw,

        safe_divide(
            revenue_7_day_sma,
            revenue_14_day_sma
        ) as revenue_7_day_vs_14_day_sma_raw,

        safe_divide(
            revenue_per_session_7_day_sma,
            revenue_per_session_14_day_sma
        ) as revenue_per_session_7_day_vs_14_day_sma_raw,

        --------------------------------------------------
        -- ATTENTION ANOMALY METRICS
        --------------------------------------------------

        safe_divide(
            total_sessions - prior_14_day_avg_sessions,
            prior_14_day_stddev_sessions
        ) as sessions_14_day_z_score_raw,

        total_sessions
            - prior_14_day_avg_sessions
            as sessions_vs_recent_baseline_amount_raw,

        safe_divide(
            total_sessions,
            prior_14_day_avg_sessions
        ) as sessions_vs_recent_baseline_ratio_raw,

        --------------------------------------------------
        -- MONETIZATION ANOMALY METRICS
        --------------------------------------------------

        safe_divide(
            purchase_revenue - prior_14_day_avg_revenue,
            prior_14_day_stddev_revenue
        ) as revenue_14_day_z_score_raw,

        purchase_revenue
            - prior_14_day_avg_revenue
            as revenue_vs_recent_baseline_amount_raw,

        safe_divide(
            purchase_revenue,
            prior_14_day_avg_revenue
        ) as revenue_vs_recent_baseline_ratio_raw,

        safe_divide(
            transactions - prior_14_day_avg_transactions,
            prior_14_day_stddev_transactions
        ) as transactions_14_day_z_score_raw,

        transactions
            - prior_14_day_avg_transactions
            as transactions_vs_recent_baseline_amount_raw,

        safe_divide(
            transactions,
            prior_14_day_avg_transactions
        ) as transactions_vs_recent_baseline_ratio_raw,

        --------------------------------------------------
        -- EFFICIENCY ANOMALY METRICS
        --------------------------------------------------

        safe_divide(
            revenue_per_session_raw
                - prior_14_day_avg_revenue_per_session,
            prior_14_day_stddev_revenue_per_session
        ) as revenue_per_session_14_day_z_score_raw,

        revenue_per_session_raw
            - prior_14_day_avg_revenue_per_session
            as revenue_per_session_vs_recent_baseline_amount_raw,

        safe_divide(
            revenue_per_session_raw,
            prior_14_day_avg_revenue_per_session
        ) as revenue_per_session_vs_recent_baseline_ratio_raw,

        --------------------------------------------------
        -- EFFICIENCY DRIVER METRICS
        --------------------------------------------------

        safe_divide(
            session_conversion_rate_raw
                - prior_14_day_avg_conversion_rate,
            prior_14_day_stddev_conversion_rate
        ) as conversion_rate_14_day_z_score_raw,

        safe_divide(
            session_conversion_rate_raw,
            prior_14_day_avg_conversion_rate
        ) as conversion_rate_vs_recent_baseline_ratio_raw,

        safe_divide(
            average_order_value_raw
                - prior_14_day_avg_aov,
            prior_14_day_stddev_aov
        ) as aov_14_day_z_score_raw,

        safe_divide(
            average_order_value_raw,
            prior_14_day_avg_aov
        ) as aov_vs_recent_baseline_ratio_raw

    from rolling_metrics

),

classified_dimensions as (

    select
        comparison_metrics.*,

        --------------------------------------------------
        -- KNOWN BUSINESS PERIOD
        --------------------------------------------------

        case
            when session_date between date '2020-11-27'
                and date '2020-11-30'
                then 'black_friday_to_cyber_monday'
            else null
        end as known_period,

        --------------------------------------------------
        -- ATTENTION TREND
        --------------------------------------------------

        case
            when sessions_7_day_vs_14_day_sma_raw >= 1.05
                then 'upward_trend'

            when sessions_7_day_vs_14_day_sma_raw <= 0.95
                then 'downward_trend'

            else 'stable_trend'
        end as attention_trend_status,

        --------------------------------------------------
        -- MONETIZATION TREND
        --------------------------------------------------

        case
            when revenue_7_day_vs_14_day_sma_raw >= 1.05
                then 'upward_trend'

            when revenue_7_day_vs_14_day_sma_raw <= 0.95
                then 'downward_trend'

            else 'stable_trend'
        end as monetization_trend_status,

        --------------------------------------------------
        -- EFFICIENCY TREND
        --------------------------------------------------

        case
            when revenue_per_session_7_day_vs_14_day_sma_raw >= 1.05
                then 'upward_trend'

            when revenue_per_session_7_day_vs_14_day_sma_raw <= 0.95
                then 'downward_trend'

            else 'stable_trend'
        end as efficiency_trend_status,

        --------------------------------------------------
        -- ATTENTION ANOMALY STATUS
        --------------------------------------------------

        case
            when prior_14_day_observations < 14
                then 'insufficient_history'

            when sessions_14_day_z_score_raw
                    >= parameters.anomaly_z_threshold
             and sessions_vs_recent_baseline_ratio_raw
                    >= parameters.attention_spike_ratio_threshold
                then 'attention_spike'

            when sessions_14_day_z_score_raw
                    <= -parameters.anomaly_z_threshold
             and sessions_vs_recent_baseline_ratio_raw
                    <= parameters.attention_drop_ratio_threshold
                then 'attention_drop'

            else 'normal_attention'
        end as attention_status,

        --------------------------------------------------
        -- MONETIZATION ANOMALY STATUS
        --------------------------------------------------

        case
            when prior_14_day_observations < 14
                then 'insufficient_history'

            when revenue_14_day_z_score_raw
                    >= parameters.anomaly_z_threshold
             and revenue_vs_recent_baseline_amount_raw
                    >= parameters.positive_revenue_impact_threshold
             and (
                    transactions_14_day_z_score_raw
                        >= parameters.anomaly_z_threshold

                    or revenue_vs_recent_baseline_ratio_raw
                        >= parameters.strong_revenue_spike_ratio_threshold
                 )
                then 'monetization_spike'

            when revenue_14_day_z_score_raw
                    <= -parameters.anomaly_z_threshold
             and revenue_vs_recent_baseline_amount_raw
                    <= parameters.negative_revenue_impact_threshold
             and (
                    transactions_14_day_z_score_raw
                        <= -parameters.anomaly_z_threshold

                    or revenue_vs_recent_baseline_ratio_raw
                        <= parameters.strong_revenue_drop_ratio_threshold
                 )
                then 'monetization_drop'

            else 'normal_monetization'
        end as monetization_status,

        --------------------------------------------------
        -- EFFICIENCY ANOMALY STATUS
        --------------------------------------------------

        case
            when prior_14_day_observations < 14
                then 'insufficient_history'

            when revenue_per_session_14_day_z_score_raw
                    >= parameters.anomaly_z_threshold
             and revenue_per_session_vs_recent_baseline_ratio_raw
                    >= parameters.efficiency_spike_ratio_threshold
                then 'efficiency_spike'

            when revenue_per_session_14_day_z_score_raw
                    <= -parameters.anomaly_z_threshold
             and revenue_per_session_vs_recent_baseline_ratio_raw
                    <= parameters.efficiency_drop_ratio_threshold
                then 'efficiency_drop'

            else 'normal_efficiency'
        end as efficiency_status

    from comparison_metrics
    cross join parameters

),

efficiency_classification as (

    select
        *,

        case
            when efficiency_status = 'efficiency_spike'
             and conversion_rate_14_day_z_score_raw >= 2
             and aov_14_day_z_score_raw >= 2
                then 'conversion_and_order_value'

            when efficiency_status = 'efficiency_spike'
             and conversion_rate_14_day_z_score_raw >= 2
                then 'higher_conversion_rate'

            when efficiency_status = 'efficiency_spike'
             and aov_14_day_z_score_raw >= 2
                then 'higher_average_order_value'

            when efficiency_status = 'efficiency_drop'
             and conversion_rate_14_day_z_score_raw <= -2
             and aov_14_day_z_score_raw <= -2
                then 'conversion_and_order_value'

            when efficiency_status = 'efficiency_drop'
             and conversion_rate_14_day_z_score_raw <= -2
                then 'lower_conversion_rate'

            when efficiency_status = 'efficiency_drop'
             and aov_14_day_z_score_raw <= -2
                then 'lower_average_order_value'

            when efficiency_status in (
                'efficiency_spike',
                'efficiency_drop'
            )
                then 'mixed_or_unconfirmed'

            else null
        end as efficiency_driver

    from classified_dimensions

),

business_patterns as (

    select
        *,

        case
            when prior_14_day_observations < 14
                then 'insufficient_history'

            when attention_status = 'attention_spike'
            and monetization_status = 'monetization_spike'
            and efficiency_status = 'efficiency_spike'
                then 'high_volume_high_efficiency_growth'

            when attention_status = 'attention_spike'
            and monetization_status = 'monetization_spike'
                then 'traffic_led_revenue_growth'

            when monetization_status = 'monetization_spike'
            and efficiency_status = 'efficiency_spike'
            and attention_status != 'attention_spike'
                then 'efficiency_led_revenue_growth'

            -- Revenue materially outperformed even though traffic
            -- and efficiency did not cross formal anomaly thresholds.
            when monetization_status = 'monetization_spike'
            and attention_status = 'normal_attention'
                then 'monetization_led_growth'

            -- Large traffic spike without proportional revenue lift.
            when attention_status = 'attention_spike'
            and monetization_status = 'normal_monetization'
            and revenue_per_session_vs_recent_baseline_ratio_raw < 1
                then 'unmonetized_attention_spike'

            when attention_status = 'attention_drop'
            and monetization_status = 'monetization_drop'
                then 'broad_demand_slowdown'

            when monetization_status = 'monetization_drop'
            and efficiency_status = 'efficiency_drop'
            and attention_status != 'attention_drop'
                then 'monetization_efficiency_issue'

            when attention_status = 'attention_drop'
            and monetization_status != 'monetization_drop'
            and efficiency_status = 'efficiency_spike'
                then 'lower_traffic_with_resilient_revenue'

            when attention_status = 'normal_attention'
            and monetization_status = 'normal_monetization'
            and efficiency_status = 'normal_efficiency'
                then 'normal_daily_pattern'

            else 'mixed_performance_signal'
        end as business_performance_pattern,

        case
            when attention_status in (
                'attention_spike',
                'attention_drop'
            )
              or monetization_status in (
                'monetization_spike',
                'monetization_drop'
            )
              or efficiency_status in (
                'efficiency_spike',
                'efficiency_drop'
            )
                then true
            else false
        end as is_notable_day

    from efficiency_classification

),

recent_context as (

    select
        *,

        max(
            case
                when monetization_status = 'monetization_spike'
                    then 1
                else 0
            end
        ) over (
            order by session_date
            rows between 3 preceding and 1 preceding
        ) = 1 as follows_recent_monetization_spike

    from business_patterns

),

final_analysis as (

    select
        --------------------------------------------------
        -- DAILY PERFORMANCE
        --------------------------------------------------

        session_date,
        total_sessions,
        purchase_sessions,
        transactions,
        round(purchase_revenue, 2) as purchase_revenue,

        round(
            100 * session_conversion_rate_raw,
            2
        ) as session_conversion_rate_pct,

        round(
            average_order_value_raw,
            2
        ) as average_order_value,

        round(
            revenue_per_session_raw,
            2
        ) as revenue_per_session,

        --------------------------------------------------
        -- TREND
        --------------------------------------------------

        round(
            sessions_7_day_sma,
            2
        ) as sessions_7_day_sma,

        round(
            sessions_14_day_sma,
            2
        ) as sessions_14_day_sma,

        round(
            sessions_7_day_vs_14_day_sma_raw,
            2
        ) as sessions_7_day_vs_14_day_sma,

        attention_trend_status,

        round(
            revenue_7_day_sma,
            2
        ) as revenue_7_day_sma,

        round(
            revenue_14_day_sma,
            2
        ) as revenue_14_day_sma,

        round(
            revenue_7_day_vs_14_day_sma_raw,
            2
        ) as revenue_7_day_vs_14_day_sma,

        monetization_trend_status,

        round(
            revenue_per_session_7_day_sma,
            2
        ) as revenue_per_session_7_day_sma,

        round(
            revenue_per_session_14_day_sma,
            2
        ) as revenue_per_session_14_day_sma,

        round(
            revenue_per_session_7_day_vs_14_day_sma_raw,
            2
        ) as revenue_per_session_7_day_vs_14_day_sma,

        efficiency_trend_status,

        --------------------------------------------------
        -- BUSINESS CLASSIFICATION
        --------------------------------------------------

        attention_status,
        monetization_status,
        efficiency_status,
        efficiency_driver,
        business_performance_pattern,

        known_period,
        follows_recent_monetization_spike,
        is_notable_day,

        --------------------------------------------------
        -- ATTENTION DIAGNOSTICS
        --------------------------------------------------

        prior_14_day_observations,

        round(
            prior_14_day_avg_sessions,
            2
        ) as prior_14_day_avg_sessions,

        round(
            sessions_vs_recent_baseline_amount_raw,
            2
        ) as sessions_vs_recent_baseline_amount,

        round(
            sessions_vs_recent_baseline_ratio_raw,
            2
        ) as sessions_vs_recent_baseline_ratio,

        round(
            sessions_14_day_z_score_raw,
            2
        ) as sessions_14_day_z_score,

        --------------------------------------------------
        -- MONETIZATION DIAGNOSTICS
        --------------------------------------------------

        round(
            prior_14_day_avg_revenue,
            2
        ) as prior_14_day_avg_revenue,

        round(
            revenue_vs_recent_baseline_amount_raw,
            2
        ) as revenue_vs_recent_baseline_amount,

        round(
            revenue_vs_recent_baseline_ratio_raw,
            2
        ) as revenue_vs_recent_baseline_ratio,

        round(
            revenue_14_day_z_score_raw,
            2
        ) as revenue_14_day_z_score,

        round(
            prior_14_day_avg_transactions,
            2
        ) as prior_14_day_avg_transactions,

        round(
            transactions_vs_recent_baseline_amount_raw,
            2
        ) as transactions_vs_recent_baseline_amount,

        round(
            transactions_vs_recent_baseline_ratio_raw,
            2
        ) as transactions_vs_recent_baseline_ratio,

        round(
            transactions_14_day_z_score_raw,
            2
        ) as transactions_14_day_z_score,

        --------------------------------------------------
        -- EFFICIENCY DIAGNOSTICS
        --------------------------------------------------

        round(
            prior_14_day_avg_revenue_per_session,
            2
        ) as prior_14_day_avg_revenue_per_session,

        round(
            revenue_per_session_vs_recent_baseline_amount_raw,
            2
        ) as revenue_per_session_vs_recent_baseline_amount,

        round(
            revenue_per_session_vs_recent_baseline_ratio_raw,
            2
        ) as revenue_per_session_vs_recent_baseline_ratio,

        round(
            revenue_per_session_14_day_z_score_raw,
            2
        ) as revenue_per_session_14_day_z_score,

        round(
            conversion_rate_vs_recent_baseline_ratio_raw,
            2
        ) as conversion_rate_vs_recent_baseline_ratio,

        round(
            conversion_rate_14_day_z_score_raw,
            2
        ) as conversion_rate_14_day_z_score,

        round(
            aov_vs_recent_baseline_ratio_raw,
            2
        ) as aov_vs_recent_baseline_ratio,

        round(
            aov_14_day_z_score_raw,
            2
        ) as aov_14_day_z_score

    from recent_context

)

select
    session_date,
    total_sessions,
    transactions,
    purchase_revenue,
    revenue_per_session,

    attention_status,
    monetization_status,
    efficiency_status,
    efficiency_driver,
    business_performance_pattern,

    sessions_14_day_z_score,
    sessions_vs_recent_baseline_ratio,

    revenue_14_day_z_score,
    revenue_vs_recent_baseline_amount,
    revenue_vs_recent_baseline_ratio,
    transactions_14_day_z_score,

    revenue_per_session_14_day_z_score,
    revenue_per_session_vs_recent_baseline_ratio,

    conversion_rate_14_day_z_score,
    aov_14_day_z_score,

    known_period,
    follows_recent_monetization_spike

from final_analysis

where is_notable_day
   or known_period is not null

order by session_date