-- Creación de base de datos
CREATE database creditos;
USE creditos
GO

-- Creación de esquemas
CREATE SCHEMA source; --Esquema utilizado para las tablas de origen: simulación del sistema transaccional
GO
CREATE SCHEMA analytics; --Esquema utilizado para las tablas del modelo dimesnional estrella
GO

  -- Creación de tablas
/* 1. Tabla de clientes: base para la identificación de las PYMES:
Un cliente puede tener múltiples créditos*/

    CREATE TABLE source.customers (
        customer_id INT PRIMARY KEY
    );

-- 2. Tabla créditos: Evento principal (originación de créditos)

    CREATE TABLE source.credits (
        credit_id INT PRIMARY KEY,
        customer_id INT NOT NULL,    -- Unión con la tabla customers
        origination_date DATE NOT NULL, 
        amount DECIMAL(12,2) NOT NULL,
        term_months INT NOT NULL,
        interest_rate DECIMAL(5,4) NOT NULL,
        status VARCHAR(15) NOT NULL,

        CONSTRAINT fk_credit_customer  -- Condición: un crédito solo puede existir si el cliente existe
            FOREIGN KEY (customer_id)
            REFERENCES source.customers(customer_id)
    );

-- 3. Tabla de pagos: Representa los pah¿gos realizados sobre los créditos (un crédito tiene multiples pagos)

    CREATE TABLE source.payments (
        payment_id INT PRIMARY KEY,
        credit_id INT NOT NULL,
        payment_date DATE NOT NULL,
        amount_paid DECIMAL(12,2) NOT NULL,
        days_late INT DEFAULT 0,

        CONSTRAINT fk_payment_credit  -- Condición: Un pago debe pertenecer a un crédito existente
            FOREIGN KEY (credit_id)
            REFERENCES source.credits(credit_id)
    );


/* Modelo dimensional
 1. Dimensión Tiempo */

        CREATE TABLE analytics.dim_date (
            date_key INT PRIMARY KEY,      
            full_date DATE NOT NULL,
            month INT NOT NULL,
            year INT NOT NULL,
            year_month VARCHAR(7)       
        );

-- 2. Dimensión Cliente
        CREATE TABLE analytics.dim_customer (
            customer_key INT PRIMARY KEY, 
            customer_id INT NOT NULL,      -- ID del sistema fuente
            customer_name VARCHAR(100)
        );

-- 3. Dimensión Estado: 
        CREATE TABLE analytics.dim_status (
            status_key INT PRIMARY KEY,
            status_name VARCHAR(15)        
        );

/* 4. Tabla de Hechos
Granularidad: 1 fila = 1 crédio originado */

        CREATE TABLE analytics.fact_credits (
            credit_id INT PRIMARY KEY,    
            date_key INT NOT NULL,         -- FK a dim_date
            customer_key INT NOT NULL,     -- FK a dim_customer
            status_key INT NOT NULL,       -- FK a dim_status
            amount DECIMAL(12,2),          
            interest_rate DECIMAL(5,4),    
            term_months INT,
            CONSTRAINT fk_fact_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key),
            CONSTRAINT fk_fact_customer FOREIGN KEY (customer_key) REFERENCES analytics.dim_customer(customer_key),
            CONSTRAINT fk_fact_status FOREIGN KEY (status_key) REFERENCES analytics.dim_status(status_key)
        );

        
     