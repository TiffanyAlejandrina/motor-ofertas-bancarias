/*
 EXAMEN TECNICO - ANALISTA DE DATOS Y SOLUCION DE PROBLEMAS
 PARTE A - EXPLORACION Y LIMPIEZA (SQL SERVER)

 Base de datos: EvaluacionOfertasBancarias
 Fuente: datos_clientes.csv (605 solicitudes)

 USO:
 1. Importar el CSV mediante SSMS a dbo.datos_clientes (12 columnas).
    El asistente Import Flat File puede crear esta tabla. Para conservar
    anomalías, importar las columnas como NVARCHAR y permitir NULL.
 2. Ejecutar este archivo completo. Puede repetirse: NO borra datos originales,
    NO duplica filas y reconstruye únicamente las tablas/vistas derivadas.
 3. Si dbo.clientes ya tiene 605 filas, el script las conserva.

 NOTA: La importación desde un CSV local no se automatiza aquí porque la ruta
 y los permisos dependen del equipo. No se crean datos ficticios.
*/

USE EvaluacionOfertasBancarias;
GO

/* 01. TABLA ORIGINAL: se crea solamente si no existe. */
IF OBJECT_ID(N'dbo.clientes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.clientes (
        id_cliente VARCHAR(50) NULL,
        edad VARCHAR(50) NULL,
        ingreso_mensual VARCHAR(50) NULL,
        indice_confiabilidad VARCHAR(50) NULL,
        meses_en_empleo VARCHAR(50) NULL,
        productos_contratados VARCHAR(50) NULL,
        pago_mensual_deudas VARCHAR(50) NULL,
        dias_atraso_maximo VARCHAR(50) NULL,
        producto_solicitado VARCHAR(100) NULL,
        monto_solicitado VARCHAR(50) NULL,
        departamento VARCHAR(100) NULL,
        canal VARCHAR(100) NULL
    );
END;
GO

/* 02. COPIA DESDE TABLA DE IMPORTACION: solamente si clientes esta vacia.
   Evita que volver a ejecutar el script duplique las solicitudes. */
IF NOT EXISTS (SELECT 1 FROM dbo.clientes)
BEGIN
    IF OBJECT_ID(N'dbo.datos_clientes', N'U') IS NULL
        THROW 50001, 'Importe primero datos_clientes.csv en dbo.datos_clientes.', 1;

    INSERT INTO dbo.clientes (
        id_cliente, edad, ingreso_mensual, indice_confiabilidad,
        meses_en_empleo, productos_contratados, pago_mensual_deudas,
        dias_atraso_maximo, producto_solicitado, monto_solicitado,
        departamento, canal
    )
    SELECT
        id_cliente, edad, ingreso_mensual, indice_confiabilidad,
        meses_en_empleo, productos_contratados, pago_mensual_deudas,
        dias_atraso_maximo, producto_solicitado, monto_solicitado,
        departamento, canal
    FROM dbo.datos_clientes;
END;
GO

/* 03. CONTEO ORIGINAL (esperado con el CSV suministrado: 605). */
SELECT COUNT(*) AS total_registros_originales FROM dbo.clientes;
GO

/* 04. DIAGNOSTICO INICIAL: vacios, negativos y edades imposibles.
   TRY_CONVERT evita errores por texto no numerico. */
SELECT
    COUNT(*) AS total_registros,
    SUM(CASE WHEN ingreso_mensual IS NULL OR LTRIM(RTRIM(ingreso_mensual)) = '' THEN 1 ELSE 0 END) AS ingresos_vacios,
    SUM(CASE WHEN indice_confiabilidad IS NULL OR LTRIM(RTRIM(indice_confiabilidad)) = '' THEN 1 ELSE 0 END) AS indices_vacios,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) < 0 THEN 1 ELSE 0 END) AS ingresos_negativos,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), monto_solicitado) < 0 THEN 1 ELSE 0 END) AS montos_negativos,
    SUM(CASE WHEN TRY_CONVERT(INT, edad) < 0 OR TRY_CONVERT(INT, edad) > 120 THEN 1 ELSE 0 END) AS edades_imposibles
FROM dbo.clientes;
GO

/* 05. IDENTIFICADORES REPETIDOS: un ID repetido no necesariamente implica
   filas identicas. Se comprueba a continuacion. */
SELECT id_cliente, COUNT(*) AS cantidad_repeticiones
FROM dbo.clientes
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY cantidad_repeticiones DESC, id_cliente;
GO

/* 06. FILAS DE IDENTIFICADORES REPETIDOS PARA INSPECCION. */
SELECT c.*
FROM dbo.clientes AS c
WHERE EXISTS (
    SELECT 1 FROM dbo.clientes AS x
    WHERE x.id_cliente = c.id_cliente
    GROUP BY x.id_cliente
    HAVING COUNT(*) > 1
)
ORDER BY c.id_cliente;
GO

/* 07. DUPLICADOS EXACTOS: comparar las 12 columnas, incluyendo NULL. */
SELECT
    id_cliente, edad, ingreso_mensual, indice_confiabilidad,
    meses_en_empleo, productos_contratados, pago_mensual_deudas,
    dias_atraso_maximo, producto_solicitado, monto_solicitado,
    departamento, canal,
    COUNT(*) AS repeticiones
FROM dbo.clientes
GROUP BY
    id_cliente, edad, ingreso_mensual, indice_confiabilidad,
    meses_en_empleo, productos_contratados, pago_mensual_deudas,
    dias_atraso_maximo, producto_solicitado, monto_solicitado,
    departamento, canal
HAVING COUNT(*) > 1;
GO

/* 08. TABLA DERIVADA SIN DUPLICADOS EXACTOS.
   Se conserva dbo.clientes para auditoria. Se recrea solo la tabla derivada.
   Con el CSV analizado: 605 filas originales -> 600 filas distintas. */
DROP VIEW IF EXISTS dbo.vw_validacion_clientes;
DROP VIEW IF EXISTS dbo.vw_clientes_procesados;
DROP TABLE IF EXISTS dbo.clientes_limpios;
GO
SELECT DISTINCT *
INTO dbo.clientes_limpios
FROM dbo.clientes;
GO
SELECT COUNT(*) AS total_clientes_limpios FROM dbo.clientes_limpios;
GO

/* 09. DETECCION DE DATOS INVALIDOS EN CAMPOS FINANCIEROS Y EDAD.
   Es un criterio de calidad, distinto de las reglas bancarias de rechazo.
   Los registros con faltantes se revisan; no se imputan valores ficticios. */
SELECT
    id_cliente, edad, ingreso_mensual, indice_confiabilidad,
    pago_mensual_deudas, monto_solicitado
FROM dbo.clientes_limpios
WHERE TRY_CONVERT(INT, edad) IS NULL
   OR TRY_CONVERT(INT, edad) < 0
   OR TRY_CONVERT(INT, edad) > 120
   OR TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) <= 0
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) < 0
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) > 1000
   OR TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) < 0
   OR TRY_CONVERT(DECIMAL(18,2), monto_solicitado) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), monto_solicitado) < 0;
GO

/* 10. CONTEO DE REGISTROS INVALIDOS SEGUN LOS MISMOS CRITERIOS. */
SELECT COUNT(*) AS total_clientes_invalidos
FROM dbo.clientes_limpios
WHERE TRY_CONVERT(INT, edad) IS NULL
   OR TRY_CONVERT(INT, edad) < 0
   OR TRY_CONVERT(INT, edad) > 120
   OR TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) <= 0
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) < 0
   OR TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) > 1000
   OR TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) < 0
   OR TRY_CONVERT(DECIMAL(18,2), monto_solicitado) IS NULL
   OR TRY_CONVERT(DECIMAL(18,2), monto_solicitado) < 0;
GO

/* 11. GRUPOS DE CONFIABILIDAD: promedio de ingreso y porcentaje de deuda.
   Se consideran ingresos positivos, deudas no negativas e indices 500-1000.
   Este reporte descriptivo NO equivale a clientes aprobados. */
WITH ClientesValidos AS (
    SELECT
        TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) AS ingreso,
        TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) AS indice,
        TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) AS deuda
    FROM dbo.clientes_limpios
)
SELECT
    CASE
        WHEN indice BETWEEN 500 AND 649 THEN 'Basico'
        WHEN indice BETWEEN 650 AND 799 THEN 'Bueno'
        WHEN indice BETWEEN 800 AND 1000 THEN 'Excelente'
    END AS grupo,
    COUNT(*) AS total_clientes,
    ROUND(AVG(ingreso), 2) AS ingreso_promedio,
    ROUND(AVG((deuda / NULLIF(ingreso, 0)) * 100), 2) AS porcentaje_deuda_promedio
FROM ClientesValidos
WHERE ingreso > 0 AND deuda >= 0 AND indice BETWEEN 500 AND 1000
GROUP BY CASE
    WHEN indice BETWEEN 500 AND 649 THEN 'Basico'
    WHEN indice BETWEEN 650 AND 799 THEN 'Bueno'
    WHEN indice BETWEEN 800 AND 1000 THEN 'Excelente'
END
ORDER BY grupo;
GO

/* 12. DISTRIBUCION DE VALORES CATEGORICOS: ayuda a detectar variantes
   de texto en producto, canal y departamento. */
SELECT 'producto_solicitado' AS campo, producto_solicitado AS valor, COUNT(*) AS cantidad
FROM dbo.clientes_limpios GROUP BY producto_solicitado
UNION ALL
SELECT 'canal', canal, COUNT(*) FROM dbo.clientes_limpios GROUP BY canal
UNION ALL
SELECT 'departamento', departamento, COUNT(*) FROM dbo.clientes_limpios GROUP BY departamento
ORDER BY campo, valor;
GO

/* 13. VALIDACION DE LOS OTROS CAMPOS NUMERICOS. */
SELECT
    COUNT(*) AS total_registros,
    SUM(CASE WHEN TRY_CONVERT(INT, meses_en_empleo) IS NULL OR TRY_CONVERT(INT, meses_en_empleo) < 0 THEN 1 ELSE 0 END) AS empleo_invalido,
    SUM(CASE WHEN TRY_CONVERT(INT, productos_contratados) IS NULL OR TRY_CONVERT(INT, productos_contratados) < 0 THEN 1 ELSE 0 END) AS productos_invalidos,
    SUM(CASE WHEN TRY_CONVERT(INT, dias_atraso_maximo) IS NULL OR TRY_CONVERT(INT, dias_atraso_maximo) < 0 THEN 1 ELSE 0 END) AS atrasos_invalidos
FROM dbo.clientes_limpios;
GO

/* 14. VISTA DE TIPADO Y NORMALIZACION.
   No altera las tablas originales ni reemplaza NULL con supuestos. */
CREATE VIEW dbo.vw_clientes_procesados AS
SELECT
    TRY_CONVERT(INT, id_cliente) AS id_cliente,
    TRY_CONVERT(INT, edad) AS edad,
    TRY_CONVERT(DECIMAL(18,2), ingreso_mensual) AS ingreso_mensual,
    TRY_CONVERT(DECIMAL(18,2), indice_confiabilidad) AS indice_confiabilidad,
    TRY_CONVERT(INT, meses_en_empleo) AS meses_en_empleo,
    TRY_CONVERT(INT, productos_contratados) AS productos_contratados,
    TRY_CONVERT(DECIMAL(18,2), pago_mensual_deudas) AS pago_mensual_deudas,
    TRY_CONVERT(INT, dias_atraso_maximo) AS dias_atraso_maximo,
    LOWER(LTRIM(RTRIM(producto_solicitado))) AS producto_solicitado,
    TRY_CONVERT(DECIMAL(18,2), monto_solicitado) AS monto_solicitado,
    LTRIM(RTRIM(departamento)) AS departamento,
    LTRIM(RTRIM(canal)) AS canal
FROM dbo.clientes_limpios;
GO
SELECT COUNT(*) AS total_registros FROM dbo.vw_clientes_procesados;
GO

/* 15. VISTA DE VALIDACION DE CALIDAD.
   REQUIERE_REVISION no significa rechazo crediticio.
   No se inventan ingresos o indices faltantes. */
CREATE VIEW dbo.vw_validacion_clientes AS
SELECT *,
    CASE
        WHEN id_cliente IS NULL
          OR edad IS NULL OR edad < 0 OR edad > 120
          OR ingreso_mensual IS NULL OR ingreso_mensual <= 0
          OR indice_confiabilidad IS NULL OR indice_confiabilidad < 0 OR indice_confiabilidad > 1000
          OR meses_en_empleo IS NULL OR meses_en_empleo < 0
          OR productos_contratados IS NULL OR productos_contratados < 0
          OR pago_mensual_deudas IS NULL OR pago_mensual_deudas < 0
          OR dias_atraso_maximo IS NULL OR dias_atraso_maximo < 0
          OR monto_solicitado IS NULL OR monto_solicitado < 0
          OR producto_solicitado NOT IN ('tarjeta', 'credito', 'combinado')
        THEN 'REQUIERE_REVISION'
        ELSE 'VALIDO'
    END AS estado_validacion
FROM dbo.vw_clientes_procesados;
GO
SELECT estado_validacion, COUNT(*) AS cantidad_clientes
FROM dbo.vw_validacion_clientes
GROUP BY estado_validacion;
GO

/* RESULTADOS OBSERVADOS EN LA SESION:
   605 registros originales, 5 duplicados exactos adicionales, 600 unicos.
   49 requieren revision; 551 validos segun la vista.
   Las cifras son verificables ejecutando las consultas sobre el CSV dado.

   IMPORTANTE PARA PARTE B:
   Las reglas del banco se aplican DESPUES de esta validacion de calidad.
   No confundir 'REQUIERE_REVISION' con 'rechazo' por riesgo crediticio.
*/
