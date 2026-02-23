# Analisis-de-credito

Este proyecto implementa un modelo dimensional orientado al análisis de créditos financieros.
Incluye la simulación de datos transaccionales (OLTP), su transformación hacia un modelo dimensional tipo estrella, y un conjunto de consultas SQL diseñadas para obtener métricas de negocio relacionadas con el desempeño crediticio.
## Supuestos Realizados
- Cada crédito pertenece a un único cliente.
- Un cliente puede tener múltiples créditos (relación 1:N).
- Un crédito puede tener múltiples pagos asociados (relación 1:N).
- Las fechas se encuentran en formato UTC.
- No existen registros duplicados en la fuente transaccional.
- El estado "default" corresponde a créditos que nunca recibieron pagos.
- Se considera implícitamente la entidad Customer como actor principal del sistema.
## Diseño del modelo
### Enfoque
Se eligió un modelo estrella debido a que optimiza consultas analíticas mediante:
- Menor cantidad de joins.
- Mejor rendimiento en agregaciones.
- Mayor simplicidad para análisis de negocio.
### Granularidad
La tabla de hechos **fact_credits** tiene granularidad a nivel de **crédito individual**:
Cada fila representa un contrato de crédito en su momento de originación.
Esto permite analizar:
- Cohortes de originación
- Desempeño
- Tasas de mora y default
### Tabla de Hechos
Contiene métricas del negocio:
- Monto del crédito.
- Plazo.
- Tasa de interés.
### Tablas de Dimensión:
Se implementaron las siguientes dimensiones:
1. **dim_date**: Permite análisis temporal y cohortes de originación
2. **dim_customer**: Identifica al dueño del crédito
3. **dim_status**: Describe el estado del crédito
## Decisiones técnicas
### Atributos del crédito
No se creó una dimensión independiente para créditos debido a que atributos como tasa de interés o plazo:
- Son altamente específicos por registro
- Pueden almacenarse directamente en la tabla de hechos sin afectar el análisis.
### Arquitectura
Se implementó una arquitectura de dos capas:
1. Capa Source: Datos crudos que representan el origen transaccional.
2. Capa Analytics: Modelo dimensional tipo estrella optimizado para análisis
- Primero, se identificaron las entidades transaccionales para comprender las relaciones del sistema OLTP.
- Posteriormente, se diseñó el modelo dimensional enfocado en métricas.
- La información de payments se utiliza como fuente para cálculos derivados (mora, cumplimiento).
- Los datos simulados se cargan primero en el esquema **source**, y posteriormente se transforman al esquema **analytics**, simulando un flujo real.
## Cómo ejecutar las queries
Para replicar el análisis, siga este orden de ejecución:
1. Ejecute el script de creación de esquemas y tablas (create_tables.sql).
2. Carga Inicial: se incluyeron los scripts con todos los insert utilizados (también se  incluyó el conjunto de datos utilizados dentro de la carpeta /data).
3. Proceso ETL: Ejecutar el script de transformación (insert_data_Estrella.sql) el cual transforma los datos del esquema source y carga las tablas dimensionales y la tabla de hechos dentro del esquema analytics.
4. Consultas: Las respuestas a las preguntas de negocio se encuentran en Queries.sql
## Cómo escalaría la solución en producción
Para escalar la solución hacia un entorno productivo, se propone una arquitectura ELT en la nube basada en AWS, enfocada en escalabilidad, confiabilidad y observabilidad.
### Ingesta de Datos
Los datos serían extraídos desde el sistema OLTP (SQL Server) utilizando AWS Glue, el cual ejecutaría procesos de ingestión hacia un Data Lake en Amazon S3.  
Esta capa actuaría como zona de staging, permitiendo almacenar datos crudos antes de su transformación.
### Procesamiento y Modelado (ELT)
Se adopta un enfoque ELT donde las transformaciones se realizan directamente en el Data Warehouse (Amazon Redshift).  
Esto permite aprovechar el poder de cómputo del motor analítico y mantener separación entre:
- datos transaccionales (OLTP)
- datos crudos (Data Lake-S3)
- Data Warehouse (Redshift)
### Incrementalidad
La carga incremental se implementaría mediante una estrategia **delta load**, donde AWS Glue extrae únicamente registros nuevos o modificados utilizando columnas de fecha o última actualización.
### Calidad de datos
Se realizarían validaciones en la capa staging (S3):
1. Unicidad: que no existan pagos duplicados.
2. Integridad: Que no existan customer_id nulos.
### Observabilidad
La observabilidad del pipeline se implementaría mediante Amazon CloudWatch, permitiendo:
- Monitoreo de ejecuciones del pipeline
- Centralización de logs
- Alertas ante fallos o anomalías
- Trazabilidad del procesamiento de datos
## Validaciones
### Implementaciones futuras
1. Reglas de negocio: 
- Suma de pagos ≤ monto total del crédito
- Tasa de interés dentro de rangos válidos
### Duplicidad de pagos
- Añadir validaciones de unicidad usando una clave natural del pago, por ejemplo:
**payment_id** o, combinación **(credit_id, payment_date, amount)**:
ROW_NUMBER() OVER(PARTITION BY credit_id, payment_date, amount ORDER BY payment_id)
### Consistencia entre créditos y pagos
Validación de integridad referencial:
1. Existencia del crédito
2. Suma de pagos ≤ monto total del crédito
3. Pagos dentro del plazo del crédito
