-- Monthly ED utilization trends
SELECT
    period AS reporting_month,
    SUM(attendances) AS total_attendances,
    SUM(breaches) AS total_breaches,
    SUM(admissions) AS total_admissions,
    ROUND(
      100.0 * SUM(breaches) /
      NULLIF(SUM(attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
      100.0 * SUM(admissions) /
      NULLIF(SUM(attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity
GROUP BY period
ORDER BY period
;
