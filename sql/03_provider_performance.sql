-- Provider-level ED performance
SELECT
    e.org_code,
    COALESCE(
        p.organisation_name,
        'Provider name unavailable'
    ) AS organisation_name,
    COUNT(DISTINCT e.period) AS reporting_months,
    SUM(e.attendances) AS total_attendances,
    SUM(e.breaches) AS total_breaches,
    SUM(e.admissions) AS total_admissions,
    ROUND(
        100.0 * SUM(e.breaches) /
        NULLIF(SUM(e.attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
        100.0 * SUM(e.admissions) /
        NULLIF(SUM(e.attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity AS e
LEFT JOIN nhs_providers AS p
    ON e.org_code = p.org_code
GROUP BY
    e.org_code,
    p.organisation_name
ORDER BY total_attendances DESC
;
