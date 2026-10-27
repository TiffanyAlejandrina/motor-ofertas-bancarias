# Evaluación técnica — Sistema de decisión de ofertas

**Proyecto:** MotorOfertasBancarias  
**Tecnologías:** C#, ASP.NET Core (.NET 10), SQL Server, Microsoft.Data.SqlClient  
**Objetivo:** analizar la calidad de 605 solicitudes de clientes, depurar duplicados y aplicar las reglas de negocio para obtener una decisión por cliente.

## 1. Estructura de la entrega

```text
Evaluacion_Tecnica_Motor_Ofertas/
├── README.md
├── Parte_A_SQL/
│   ├── Parte_A_Exploracion_Limpieza.sql
│   └── datos_clientes.csv
├── Parte_B_API/
│   ├── MotorOfertasBancarias.slnx
│   ├── MotorOfertasBancarias.Api/
│   │   ├── Controllers/
│   │   ├── Models/
│   │   ├── Properties/
│   │   ├── Repositories/
│   │   ├── Services/
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   └── MotorOfertasBancarias.Api.csproj
│   └── resultado.csv
└── Parte_C_Analisis/
    ├── Parte_C_Analisis_Resultados.pdf
    └── Parte_C_Graficas_Resultados.html
```

Los archivos `bin/`, `obj/`, `.vs/` y `*.csproj.user` no son necesarios para la entrega.

## 2. Requisitos

- Windows con **SQL Server** y **SQL Server Management Studio (SSMS)**.
- **Visual Studio** compatible con proyectos `.slnx` y desarrollo de ASP.NET Core.
- **SDK de .NET 10** instalado.
- Acceso a la instancia local de SQL Server mediante autenticación de Windows, con permisos para crear base de datos, tablas y vistas.

## 3. Crear la base de datos

Conectarse a SQL Server desde SSMS y ejecutar, si la base todavía no existe:

```sql
IF DB_ID(N'EvaluacionOfertasBancarias') IS NULL
    CREATE DATABASE EvaluacionOfertasBancarias;
GO
```

## 4. Importar el CSV original en SSMS

1. En SSMS, seleccionar la base `EvaluacionOfertasBancarias`.
2. Usar **Tasks / Tareas → Import Flat File / Importar archivo plano** y seleccionar `Parte_A_SQL/datos_clientes.csv`.
3. Nombrar la tabla de destino **`dbo.datos_clientes`**.
4. Comprobar que se importen las **12 columnas** del archivo, preservando valores vacíos y datos originales. Es preferible importar las columnas como texto (`NVARCHAR`) y permitir `NULL`, para conservar las anomalías antes de limpiarlas.
5. Confirmar que se importaron **605 filas**:

```sql
USE EvaluacionOfertasBancarias;
GO
SELECT COUNT(*) AS total FROM dbo.datos_clientes;
```


## 5. Ejecutar la Parte A (SQL)

1. Abrir `Parte_A_SQL/Parte_A_Exploracion_Limpieza.sql` en SSMS.
2. Seleccionar la instancia correcta y ejecutar el script completo.
3. El script conserva `dbo.clientes` como tabla original, identifica problemas de calidad, crea `dbo.clientes_limpios` y las vistas `dbo.vw_clientes_procesados` y `dbo.vw_validacion_clientes`.
4. Resultados de referencia para el CSV proporcionado: **605 solicitudes**, **600 filas después de quitar 5 duplicados exactos** y **49 clientes que requieren revisión**.

**Advertencia:** el script reconstruye la tabla derivada `dbo.clientes_limpios` y las vistas relacionadas; **no** elimina los registros originales de `dbo.clientes`. Ejecútese sobre una base de pruebas.

## 6. Configurar la conexión SQL Server

Abrir `Parte_B_API/MotorOfertasBancarias.Api/appsettings.json` y localizar `ConnectionStrings:DefaultConnection`.

Ejemplo con autenticación integrada de Windows:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=MI_SERVIDOR;Database=EvaluacionOfertasBancarias;Trusted_Connection=True;Encrypt=True;TrustServerCertificate=True;"
  }
}
```

Sustituir `MI_SERVIDOR` por el nombre de la instancia local, por ejemplo `EQUIPO\\SQLEXPRESS`. La configuración original puede contener `Server=KAZUKI`, que corresponde únicamente al equipo de desarrollo. No se requiere contraseña SQL cuando se usa `Trusted_Connection=True` y la cuenta Windows dispone de permisos. `TrustServerCertificate=True` se utiliza aquí para el entorno local de pruebas.

## 7. Ejecutar la Parte B (API REST)

1. Abrir `Parte_B_API/MotorOfertasBancarias.slnx` con Visual Studio.
2. Esperar la restauración de paquetes NuGet.
3. Compilar la solución y establecer `MotorOfertasBancarias.Api` como proyecto de inicio.
4. Ejecutar con el perfil HTTPS. La URL local puede variar según el perfil de ejecución; durante el desarrollo se utilizó `https://localhost:7127`.
5. Consultar los endpoints (reemplazar `{baseUrl}` por la dirección que muestre Visual Studio):

| Método | Ruta | Función |
|---|---|---|
| GET | `{baseUrl}/api/clientes` | Lista los clientes procesados. |
| GET | `{baseUrl}/api/clientes/{id}` | Consulta un cliente. |
| GET | `{baseUrl}/api/clientes/{id}/evaluar` | Evalúa un cliente. |
| GET | `{baseUrl}/api/clientes/evaluar-todos` | Evalúa los 600 clientes. |
| GET | `{baseUrl}/api/clientes/exportar-csv` | Descarga `resultado.csv`. |

Ejemplo de evaluación individual: `{baseUrl}/api/clientes/100017/evaluar`.

El archivo `Parte_B_API/resultado.csv` contiene los resultados generados por el motor con las columnas `id_cliente`, `oferta_final`, `limite_tarjeta`, `monto_credito` y `motivo`. Tiene **600 registros más una fila de encabezados**.

## 8. Criterios de calidad y decisiones

- Los duplicados **exactos** se eliminan de la tabla derivada, conservando el origen para auditoría.
- Los registros incompletos o inválidos se identifican como **`REQUIERE_REVISION`**; no se inventan valores faltantes.
- Los registros válidos se evalúan conforme a las condiciones de rechazo, grupos de confiabilidad, topes y redondeos establecidos en el enunciado.
- La capacidad de pago se calcula como `max(0, ingreso_mensual × 0.40 − pago_mensual_deudas)`.
- Una oferta con importe **Q0** puede producirse cuando el cliente supera las condiciones de rechazo pero su capacidad calculada es cero. Se conserva ese comportamiento por fidelidad al enunciado y se documenta como oportunidad de mejora, no como una regla nueva.

## 9. Parte C — Análisis y gráficas

- `Parte_C_Analisis/Parte_C_Analisis_Resultados.pdf`: porcentajes de aprobación, distribución de ofertas, motivos de rechazo, suma de montos, supuestos y propuestas de mejora.
- `Parte_C_Analisis/Parte_C_Graficas_Resultados.html`: gráficas de los resultados; abrir en un navegador web.

## 10. Comprobaciones de referencia

- `dbo.vw_validacion_clientes`: **600 registros** y **600 identificadores únicos**.
- Respuesta de `/api/clientes/evaluar-todos`: `totalClientes = 600`.
- Cliente `100005`: `REQUIERE_REVISION`, montos Q0.
- Cliente `100017`: `RECHAZADO` por índice de confiabilidad menor a 500, montos Q0.

**Alcance:** solución de evaluación técnica en entorno local; la API REST es un componente adicional y no requiere despliegue en la nube para reproducir la prueba.
