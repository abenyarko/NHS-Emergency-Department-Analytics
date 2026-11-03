# NHS Emergency Department Utilization & Performance Analytics

**Healthcare Operations Analytics | R | SQL | SQLite | Power BI**

## Executive Summary

This project examines historical emergency department (ED) utilization and operational performance across NHS healthcare organizations in England from **April 2016 through March 2019**.

Using R, SQL, and SQLite, the project integrates 12,765 monthly ED activity records with organizational reference information representing 274 NHS providers.

The analysis evaluates national utilization, monthly attendance patterns, four-hour performance breaches, admissions, department-level differences, and provider reporting coverage.

**Project objective:** Transform publicly available healthcare operational data into actionable insights that support performance monitoring, resource planning, and evidence-informed decision-making.

## Business Questions

The analysis addresses five operational questions:

1. What were the national volumes of ED attendances, admissions, and four-hour breaches?
2. How did ED utilization and performance change over time?
3. How did utilization differ across emergency department categories?
4. Which providers consistently reported data, and how did their attendance volumes compare?
5. What data-quality limitations should be considered when interpreting provider performance?

## Data Sources

**NHS Emergency Department Activity**

- Source: `NHSRdatasets` R package, `ae_attendances` dataset
- Reporting period: April 2016–March 2019
- Observations: 12,765
- Distinct provider codes: 274
- Reporting months: 36

The dataset includes reporting period, provider organization code, department type, attendances, breaches, and admissions.

**NHS Organisation Data Service (ODS)**

Provider reference information was retrieved through NHS ODS organization lookups to enrich activity records with available organizational details.

The dataset contains aggregated healthcare activity, not individual patient records.

## Technology Stack

| Technology | Application |
|---|---|
| R | Data preprocessing, integration, validation, visualization |
| SQL | Data aggregation, performance metrics, provider comparisons |
| SQLite | Relational database management |
| NHS ODS API | Healthcare organization reference information |
| Power BI | Executive dashboard development |
| GitHub | Version control and technical documentation |

## Analytical Methodology

### 1. Data Preparation and Integration

- Imported and examined historical NHS ED activity data.
- Evaluated missing values, variable types, and reporting periods.
- Retrieved provider reference information using NHS ODS lookups.
- Joined provider information to emergency department activity records.

### 2. Data Quality Validation

- Checked duplicate provider identifiers.
- Examined duplicate activity records.
- Validated activity counts and relationships between measures.
- Investigated unusual records and provider reference mismatches.
- Evaluated completeness of provider reporting.

### 3. Relational Database Development

Developed a SQLite database with two principal tables:

- `nhs_providers`: Healthcare organization reference information.
- `nhs_er_activity`: Monthly emergency department activity.

The database design includes primary-key and foreign-key relationships to support consistent relational analysis.

### 4. SQL Analysis

Developed SQL queries to calculate:

- National ED attendances, breaches, and admissions.
- Breach and admission rates.
- Utilization by department type.
- Monthly utilization and performance trends.
- Provider-level activity and reporting coverage.

Department categories are preserved as recorded in the source: `1`, `2`, and `other`.

### 5. Longitudinal Trend Analysis

Analyzed 36 months of national ED activity.

Monthly attendance totals were divided by the number of calendar days in each month to create comparable average daily attendance measures.

### 6. Provider Performance Analysis

Evaluated differences in provider activity and reporting completeness.

For the primary volume rankings, comparisons were restricted to providers with all 36 months of reporting.

## Key Findings

### National Emergency Department Activity

| Performance Indicator | Result |
|---|---:|
| Total ED attendances | 72,019,402 |
| Total four-hour breaches | 8,295,237 |
| Total admissions | 13,493,280 |
| Overall breach rate | 11.52% |
| Admissions-to-attendances ratio | 18.74% |
| Providers represented | 274 |
| Reporting months | 36 |

These percentages are calculated from aggregate totals rather than averages of individual provider rates.

### Monthly Utilization Trends

Average daily ED attendance varied across the observation period.

- **Highest:** July 2018, approximately 70,319 attendances per day.
- **Lowest:** January 2017, approximately 61,138 attendances per day.

Normalizing attendance by calendar days improves comparability across months of different lengths.

### Provider Reporting Coverage

Of the 274 providers:

- **190** reported activity in all 36 months.
- **84** had incomplete reporting coverage.

Among providers with complete reporting, Barts Health NHS Trust had one of the highest average monthly attendance volumes, approximately 40,877, while Tetbury Hospital Trust Ltd had one of the lowest, approximately 189.

These are utilization comparisons, not clinical quality rankings. Differences in organization size, services, case mix, and reporting practices must be considered.

## Repository Structure

### R Analysis

- [Cleaned NHS ED Analysis Script](R/nhs_ed_analysis_clean.R)
- [Original R Development Script](R/nhs_ed_analysis.R)

### SQL Analysis

- [01 — National ED Utilization](sql/01_ed_utilization.sql)
- [02 — Monthly Utilization Trends](sql/02_monthly_trends.sql)
- [03 — Provider Performance](sql/03_provider_performance.sql)

The SQL files provide standalone examples of relational healthcare data analysis.

## Data Quality and Limitations

Several considerations are important when interpreting the results:

- The study covers historical data from 2016–2019 and does not describe current NHS performance.
- Activity records are aggregated and cannot support patient-level conclusions.
- Provider reporting coverage varies across the observation period.
- Raw provider volumes are not adjusted for organization size, case mix, or service configuration.
- NHS ODS organizational information may not perfectly reflect historical organizational arrangements.
- Unusual source records require investigation rather than automatic correction.

**Reproducibility note:** The cleaned R script has passed syntax validation, but a complete fresh-environment execution has not yet been verified. The SQLite database remains local, and the published scripts currently serve as documented analytical examples rather than a fully automated rebuild.

## Dashboard Development

A one-page Power BI dashboard is being developed to communicate the analysis through:

- National ED utilization KPIs.
- Monthly attendance trends.
- Department-type comparisons.
- Provider activity and reporting coverage.

The dashboard will be added to the repository when completed.

## Future Enhancements

Potential extensions include:

- Fully automated database initialization and reproducible data pipelines.
- Additional provider-level performance measures.
- More detailed trend and variation analysis.
- Expanded interactive reporting and operational decision-support tools.

## Project Value

This project demonstrates practical skills relevant to healthcare data analyst and healthcare analytics consultant positions, including:

- Healthcare operational data analysis.
- SQL querying and relational database development.
- Data preprocessing and quality assurance.
- API-based reference data integration.
- Longitudinal utilization analysis.
- Performance measurement and interpretation.
- Technical documentation and stakeholder reporting.

**The project is an independent analytics portfolio demonstration and is not an official NHS performance assessment.**

