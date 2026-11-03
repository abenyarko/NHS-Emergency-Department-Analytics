-- National ED utilization
SELECT
    COUNT(*) AS reporting_records,
    COUNT(DISTINCT org_code) AS total_providers,
    MIN(period) AS first_month,
    MAX(period) AS last_month,
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
;

-- ED utilization by department type
SELECT
    type AS department_type,
    COUNT(*) AS reporting_records,
    COUNT(DISTINCT org_code) AS providers,
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
GROUP BY type
ORDER BY
    CASE type
        WHEN '1' THEN 1
        WHEN '2' THEN 2
        ELSE 3
    END
;
