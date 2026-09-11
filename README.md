# Holiday Ecommerce Performance & Growth Opportunity Analysis

GA4 ecommerce analytics using BigQuery, dbt, and Data Studio to identify high-leverage opportunities across acquisition, conversion, and product performance.

## Business Question

An ecommerce team is preparing for its next holiday planning cycle. Leadership has strong topline traffic and revenue data from the prior peak season, but limited clarity on where revenue was actually won or lost across acquisition, conversion, and product performance.

The analysis addresses a practical resource-allocation question:

> **Where should limited marketing, merchandising, and conversion-optimization effort be focused before the next peak season?**

The goal is to distinguish traffic volume from traffic quality, identify conversion leakage, evaluate how effectively products turn attention into revenue, and translate those findings into prioritized recommendations.

## Dataset

The project uses the public Google Merchandise Store GA4 ecommerce sample covering November 2020 through January 2021.

Across the 92-day analysis window, the dataset contains approximately:

- 4.3 million events
- 270,000 users
- 360,000 sessions
- 4,451 transactions
- $307,000 in purchase revenue

The source data is event-level GA4 data stored in BigQuery.

## Tech Stack

- **GA4** for event-level ecommerce data
- **BigQuery** for cloud data warehousing and SQL analysis
- **dbt** for transformation, modeling, testing, and reusable business logic
- **Data Studio** for decision-oriented reporting and visualization
- **Git and GitHub** for version control and project documentation

## Analytical Architecture

```text
GA4 Event Data
      |
      v
   BigQuery
      |
      v
dbt Staging Models
      |
      v
Intermediate Models
      |
      v
Analytical Marts
      |
      v
Reporting Models
      |
      v
Data Studio Reports
```

The dbt project separates source preparation, reusable transformation logic, analytical fact tables, and reporting-specific models so that business logic is not embedded directly in the dashboard layer.

### Core fact tables

- `fct_daily_performance` for daily traffic, transactions, revenue, and conversion performance
- `fct_funnel_performance` for session behavior across key ecommerce funnel stages
- `fct_product_performance` for product demand, purchasing behavior, and revenue performance

The reporting layer contains additional models designed for presentation-specific needs such as ordered funnel stages, dashboard dimensions, and display logic.

## Reports

The final analysis is delivered through three decision-oriented reports.

### Executive Summary

Focuses on:

- overall ecommerce performance
- acquisition performance
- traffic and revenue trends
- device behavior
- key commercial KPIs

### Funnel Performance

Focuses on:

- progression through major ecommerce stages
- stage-level loss
- traffic volume
- engagement behavior
- conversion efficiency

### Product Performance

Focuses on:

- product revenue
- product demand
- purchasing behavior
- conversion efficiency
- revenue concentration

## Supporting Analysis

The repository also includes supporting analytical work used to investigate questions that do not belong directly in the reporting layer.

Examples include:

- acquisition performance
- funnel leakage
- product performance
- revenue concentration
- CPC break-even economics
- daily trend and anomaly detection
- executive performance summaries

These analyses extend the project beyond KPI reporting and help identify where additional commercial effort may have the highest expected return.

## Key Findings

### 1. Traffic volume and traffic quality are not the same

Google organic and direct traffic generated the largest session volumes, but acquisition quality varied materially by source and medium. High-volume channels should therefore not be evaluated on traffic alone.

The planning implication is to compare sources on downstream outcomes such as conversion and revenue contribution rather than assuming the largest traffic sources deserve the largest incremental investment.

### 2. Conversion improvement can create meaningful value without requiring more traffic

The site generated roughly 360,000 sessions and 4,451 transactions, with an overall session conversion rate of about 1.1 percent.

That makes conversion efficiency a material planning lever. Improvements to high-friction stages can increase revenue from traffic the business is already acquiring.

### 3. Device behavior suggests that traffic should not be treated as a single customer experience

Desktop produced more transactions and revenue than mobile during the sample period. The device split indicates that acquisition, engagement, and conversion behavior should be evaluated separately rather than only through blended sitewide KPIs.

For the next peak cycle, device-level funnel performance should be used to identify whether mobile experience improvements offer an attractive conversion opportunity.

### 4. Revenue is distributed across a relatively broad product base

Revenue concentration analysis shows that the top 10 products generated about 23 percent of revenue, while 36 products were required to reach 50 percent of total revenue.

This suggests that performance is not dependent on a single dominant product. Merchandising decisions should therefore consider a broader set of products rather than concentrating effort only on a small number of best sellers.

### 5. Product attention and product revenue should be evaluated together

Product performance varies not only by revenue, but also by how effectively product interest turns into purchases.

Products with strong demand but weak purchase efficiency can represent conversion or merchandising opportunities, while products with lower traffic but strong revenue efficiency may deserve greater visibility.

### 6. Measurement quality matters when interpreting product performance

A portion of item revenue appears without a corresponding recorded product-view event.

That does not invalidate the product analysis, but it is a reminder that behavioral event data should be validated before treating every funnel transition as a complete representation of customer behavior.

## Recommendations

### 1. Allocate acquisition budget based on downstream value, not traffic volume

Use conversion and revenue performance alongside session volume when prioritizing channels.

A source that delivers fewer sessions but materially stronger conversion can be more valuable than a much larger low-intent source.

### 2. Treat conversion optimization as a primary growth lever

The existing traffic base is large enough that relatively small improvements in conversion can produce meaningful revenue gains.

Prioritize stages with both high session volume and meaningful drop-off rather than optimizing small segments with limited commercial impact.

### 3. Evaluate mobile and desktop funnels separately

Avoid relying only on blended conversion metrics.

Use device-level funnel analysis to identify where mobile behavior diverges from desktop and whether experience changes, checkout improvements, or merchandising changes could recover lost demand.

### 4. Prioritize products using both demand and efficiency

Do not rank products only by revenue.

Combine product views, purchase behavior, conversion efficiency, and revenue contribution to identify:

- high-demand products with weak conversion
- efficient products that may be underexposed
- strong revenue contributors worth protecting
- products that consume attention without producing proportional revenue

### 5. Preserve a diversified merchandising strategy

Because revenue is not dominated by a single product, the business should avoid overconcentrating merchandising effort around only a few top sellers.

The broader product mix creates opportunities to improve category visibility, recommendation logic, and promotion strategy across a wider set of commercially relevant products.

### 6. Add measurement validation to future peak-season reporting

Investigate cases where revenue appears without expected upstream product interaction events.

For production reporting, event completeness and reconciliation checks should be treated as part of the analytics system, not as a separate cleanup task.

## Data Quality and Validation

Custom dbt tests validate important modeling assumptions, including:

- daily-performance grain
- funnel-performance grain
- product-performance grain
- product metric integrity
- revenue reconciliation

These checks help ensure that reporting outputs preserve the intended grain and that revenue remains consistent across analytical layers.

## Repository Structure

```text
ga4-ecommerce-analytics/
|
|-- analyses/                         # Supporting analytical queries
|
|-- models/
|   |-- staging/                      # Source preparation and normalization
|   |-- intermediate/                 # Reusable transformation and business logic
|   `-- marts/
|       |-- reporting/                # Dashboard-specific reporting models
|       |-- fct_daily_performance.sql
|       |-- fct_funnel_performance.sql
|       `-- fct_product_performance.sql
|
|-- tests/
|   |-- assert_fct_daily_performance_grain.sql
|   |-- assert_fct_funnel_performance_grain.sql
|   |-- assert_fct_product_performance_grain.sql
|   |-- assert_product_metric_integrity.sql
|   `-- assert_product_revenue_reconciles.sql
|
|-- macros/
|-- seeds/
|-- snapshots/
|-- dbt_project.yml
`-- README.md
```

## Modeling Approach

The project follows a layered analytics workflow.

### Staging

Staging models clean and standardize raw GA4 fields while preserving source-level meaning.

### Intermediate

Intermediate models contain reusable logic that should not be tied directly to a single dashboard or final analytical table.

### Marts

Fact tables organize the data around major analytical subjects such as daily performance, funnel behavior, and product performance.

### Reporting

Reporting models reshape analytical outputs for specific visualization or presentation requirements without moving core business logic into the BI tool.

This separation improves maintainability, makes calculations easier to validate, and allows the reporting layer to remain relatively thin.

### Cost-Aware Development

The project uses configurable `ga4_start_date` and `ga4_end_date` variables to control the GA4 source-table range.

Development began with the four-day Black Friday through Cyber Monday window, providing a small but behaviorally rich dataset for validating model grain, transaction deduplication, funnel logic, and product identity before scaling to the full dataset.

This reduced typical development query scans from roughly 1.5 GB to about 100 MB, allowing the modeling logic to be iterated on at a fraction of the full-data query cost.

After validation, the project was expanded to the complete 2020-11-01 through 2021-01-31 analysis window.

BigQuery usage was monitored through `INFORMATION_SCHEMA.JOBS_BY_PROJECT` to track query volume, bytes processed, and bytes billed during development.

## Analytical Design Principles

Several design choices guided the project:

- Separate traffic volume from traffic quality.
- Keep additive components available so rates can be recalculated correctly at different reporting grains.
- Avoid embedding core business logic in Data Studio.
- Use reporting models for presentation-specific transformations.
- Validate model grain explicitly.
- Reconcile revenue across layers.
- Use headline-oriented reporting to surface the business implication of each visual.
- Treat anomalies and concentration as decision-support tools rather than isolated statistics.

## Project Objective

This project was designed not simply to report ecommerce KPIs, but to answer a resource-allocation question:

> **Where is additional marketing, merchandising, or conversion-optimization effort most likely to improve commercial outcomes?**

The result is an end-to-end analytics workflow that moves from raw event data through tested analytical models to business-facing recommendations.
