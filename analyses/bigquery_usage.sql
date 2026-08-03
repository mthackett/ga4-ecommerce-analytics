with daily_usage as (

    select
        date(
            creation_time,
            'America/Los_Angeles'
        ) as usage_date,

        count(*) as query_jobs,

        sum(
            coalesce(total_bytes_processed, 0)
        ) as bytes_processed,

        sum(
            coalesce(total_bytes_billed, 0)
        ) as bytes_billed

    from
        `{{ target.project }}`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT

    where creation_time >= timestamp(
            date '2026-06-26',
            'America/Los_Angeles'
        )

      and job_type = 'QUERY'
      and state = 'DONE'

      -- Script parent jobs summarize their child jobs and would
      -- cause usage to be counted twice.
      and (
          statement_type is null
          or statement_type != 'SCRIPT'
      )

    group by usage_date

)

select
    usage_date,
    query_jobs,

    round(
        bytes_processed / pow(1024, 3),
        2
    ) as gib_processed,

    round(
        bytes_billed / pow(1024, 3),
        2
    ) as gib_billed,

    round(
        sum(bytes_billed) over (
            order by usage_date
            rows between unbounded preceding and current row
        ) / pow(1024, 3),
        2
    ) as cumulative_gib_billed

from daily_usage

order by usage_date desc