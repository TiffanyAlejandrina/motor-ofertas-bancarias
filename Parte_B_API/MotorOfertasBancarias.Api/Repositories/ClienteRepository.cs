using Microsoft.Data.SqlClient;
using MotorOfertasBancarias.Api.Models;
using System.Data;

namespace MotorOfertasBancarias.Api.Repositories
{
    public class ClienteRepository : IClienteRepository
    {
        private readonly string _connectionString;

        public ClienteRepository(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString(
                "DefaultConnection")
                ?? throw new InvalidOperationException(
                    "No se configuró la conexión a SQL Server.");
        }

        public async Task<List<Cliente>> ObtenerTodosAsync()
        {
            var clientes = new List<Cliente>();

            using var connection =
                new SqlConnection(_connectionString);

            await connection.OpenAsync();

            const string sql = """
                SELECT *
                FROM dbo.vw_validacion_clientes
                ORDER BY id_cliente;
                """;

            using var command = new SqlCommand(sql, connection);
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                clientes.Add(MapearCliente(reader));
            }

            return clientes;
        }

        public async Task<Cliente?> ObtenerPorIdAsync(int idCliente)
        {
            using var connection =
                new SqlConnection(_connectionString);

            await connection.OpenAsync();

            const string sql = """
                SELECT *
                FROM dbo.vw_validacion_clientes
                WHERE id_cliente = @IdCliente;
                """;

            using var command = new SqlCommand(sql, connection);

            command.Parameters.Add(
                "@IdCliente", SqlDbType.Int).Value = idCliente;

            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapearCliente(reader);
            }

            return null;
        }

        private static Cliente MapearCliente(SqlDataReader reader)
        {
            return new Cliente
            {
                IdCliente = ObtenerNullable<int>(reader, "id_cliente"),
                Edad = ObtenerNullable<int>(reader, "edad"),
                IngresoMensual = ObtenerNullable<decimal>(
                    reader, "ingreso_mensual"),
                IndiceConfiabilidad = ObtenerNullable<decimal>(
                    reader, "indice_confiabilidad"),
                MesesEnEmpleo = ObtenerNullable<int>(
                    reader, "meses_en_empleo"),
                ProductosContratados = ObtenerNullable<int>(
                    reader, "productos_contratados"),
                PagoMensualDeudas = ObtenerNullable<decimal>(
                    reader, "pago_mensual_deudas"),
                DiasAtrasoMaximo = ObtenerNullable<int>(
                    reader, "dias_atraso_maximo"),
                ProductoSolicitado = ObtenerTexto(
                    reader, "producto_solicitado"),
                MontoSolicitado = ObtenerNullable<decimal>(
                    reader, "monto_solicitado"),
                Departamento = ObtenerTexto(reader, "departamento"),
                Canal = ObtenerTexto(reader, "canal"),
                EstadoValidacion = ObtenerTexto(
                    reader, "estado_validacion")
            };
        }

        private static T? ObtenerNullable<T>(
            SqlDataReader reader, string columna) where T : struct
        {
            int indice = reader.GetOrdinal(columna);

            if (reader.IsDBNull(indice))
                return null;

            return reader.GetFieldValue<T>(indice);
        }

        private static string? ObtenerTexto(
            SqlDataReader reader, string columna)
        {
            int indice = reader.GetOrdinal(columna);

            return reader.IsDBNull(indice)
                ? null
                : reader.GetString(indice);
        }
    }
}