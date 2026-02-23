/* Carga y transformación de los datos del esquema source (OLTP) hacia el esquema analytics (modelo estrella)
-- dim_date */
INSERT INTO analytics.dim_date (
    date_key, -- se construye a apartir de las fechas de originación de los creditos
    full_date,
    year,
    month,
    year_month
)
SELECT DISTINCT
    CONVERT(INT, FORMAT(origination_date,'yyyyMMdd')) AS date_key,
    origination_date AS full_date,
    YEAR(origination_date) AS year,
    MONTH(origination_date) AS month,
    FORMAT(origination_date,'yyyy-MM') AS year_month
FROM source.credits;


--dim_customer
INSERT INTO analytics.dim_customer (
    customer_key,
    customer_id, -- se replica la llave del sistema fuente como clave analitica
    customer_name
)
SELECT
    customer_id AS customer_key,
    customer_id,
    CONCAT('Customer', customer_id) -- creacion de un nombre ficticio para mayor legibilidad
FROM source.customers;

--dim_status
INSERT INTO analytics.dim_status (
    status_key, -- se normalizan los estados del credito para evitar almacenar texto repetitivo
    status_name
)
VALUES
    (1, 'active'),
    (2, 'late'),
    (3, 'closed'),
    (4, 'default');

--Fact.table
INSERT INTO analytics.fact_credits (
    credit_id,
    date_key,
    customer_key,
    status_key,
    amount,
    interest_rate,
    term_months
)
SELECT 
    c.credit_id,
    -- Transfromación de la fecha al formato numérico de dim_date (ej: 20240501)
    CONVERT(INT, FORMAT(c.origination_date, 'yyyyMMdd')) AS date_key,
    c.customer_id AS customer_key,  -- El customer_id es la llave en dim_customer
    s.status_key, -- ID numérico de cada estatus
    c.amount,
    c.interest_rate,
    c.term_months
FROM source.credits c
INNER JOIN analytics.dim_status s ON c.status = s.status_name; -- Union con la dimensión de estatus para obtener el ID (1, 2, 3 o 4)


