-- 1. ¿Cuál es el monto total colocado por mes?
SELECT 
    d.year_month AS Mes,
    COUNT(f.credit_id) AS Cantidad_de_Creditos,
    SUM(f.amount) AS Monto_Total_Colocado
FROM analytics.fact_credits f
JOIN analytics.dim_date d ON f.date_key = d.date_key
GROUP BY d.year_month
ORDER BY d.year_month;

-- 2. ¿Cuál es la tasa de mora (créditos con días_late > 30)?
SELECT 
    CAST(100.0 * SUM(En_Mora) / COUNT(*) AS DECIMAL(5,2)) AS tasa_mora
FROM (
    SELECT 
        CASE WHEN MAX(p.days_late) > 30 THEN 1 ELSE 0 END AS En_Mora
    FROM analytics.fact_credits f
    LEFT JOIN source.payments p 
    ON f.credit_id = p.credit_id
    GROUP BY f.credit_id
) AS Resumen;

-- 3.¿Cuál es el ingreso estimado por intereses por cohorte de originación?
SELECT 
    d.year_month AS Cohorte_Originacion,
    COUNT(f.credit_id) AS Total_Creditos,
    -- Cálculo Derivado: Suma de (Monto * Tasa) para obtener el ingreso total por cohorte
    CAST(SUM(f.amount * f.interest_rate) AS DECIMAL(12,2)) AS Ingreso_Interes_Estimado
FROM analytics.fact_credits f
JOIN analytics.dim_date d ON f.date_key = d.date_key
GROUP BY d.year_month
ORDER BY d.year_month;


-- 4. ¿Cuál es el % de default por mes de originación?

SELECT 
    d.year_month AS Mes,

    COUNT(*) AS total_creditos,

    SUM(CASE 
            WHEN s.status_name = 'default' THEN 1 
            ELSE 0 
        END) AS creditos_default,
    CAST(
        100.0 *
        SUM(CASE WHEN s.status_name = 'default' THEN 1 ELSE 0 END)
        /
        COUNT(*) OVER(PARTITION BY d.year_month)
    AS DECIMAL(5,2)) AS pct_default_mes

FROM analytics.fact_credits f
JOIN analytics.dim_date d 
    ON f.date_key = d.date_key
JOIN analytics.dim_status s 
    ON f.status_key = s.status_key

GROUP BY d.year_month
ORDER BY d.year_month;



