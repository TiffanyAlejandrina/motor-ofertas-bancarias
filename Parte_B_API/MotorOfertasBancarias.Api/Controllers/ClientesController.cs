using Microsoft.AspNetCore.Mvc;
using MotorOfertasBancarias.Api.Repositories;
using MotorOfertasBancarias.Api.Services;
using System.Text;

namespace MotorOfertasBancarias.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClientesController : ControllerBase
    {
        private readonly IClienteRepository _clienteRepository;
        private readonly IMotorDecisionesService _motorDecisiones;

        public ClientesController(
            IClienteRepository clienteRepository,
            IMotorDecisionesService motorDecisiones)
        {
            _clienteRepository = clienteRepository;
            _motorDecisiones = motorDecisiones;
        }

        // GET: api/clientes
        [HttpGet]
        public async Task<IActionResult> ObtenerTodos()
        {
            var clientes = await _clienteRepository.ObtenerTodosAsync();

            return Ok(clientes);
        }

        // GET: api/clientes/100149
        [HttpGet("{id:int}")]
        public async Task<IActionResult> ObtenerPorId(int id)
        {
            var cliente = await _clienteRepository.ObtenerPorIdAsync(id);

            if (cliente == null)
                return NotFound(new
                {
                    mensaje = "Cliente no encontrado"
                });

            return Ok(cliente);
        }

        // GET: api/clientes/100149/evaluar
        [HttpGet("{id:int}/evaluar")]
        public async Task<IActionResult> EvaluarCliente(int id)
        {
            var cliente = await _clienteRepository.ObtenerPorIdAsync(id);

            if (cliente == null)
                return NotFound(new
                {
                    mensaje = "Cliente no encontrado"
                });

            var resultado = _motorDecisiones.EvaluarCliente(cliente);

            return Ok(resultado);
        }

        // GET: api/clientes/evaluar-todos
        [HttpGet("evaluar-todos")]
        public async Task<IActionResult> EvaluarTodos()
        {
            var clientes = await _clienteRepository.ObtenerTodosAsync();

            var resultados = clientes
                .Select(cliente => _motorDecisiones.EvaluarCliente(cliente))
                .ToList();

            return Ok(new
            {
                totalClientes = resultados.Count,
                resultados
            });
        }


        // GET: api/clientes/exportar-csv
        [HttpGet("exportar-csv")]
        public async Task<IActionResult> ExportarCsv()
        {
            var clientes = await _clienteRepository.ObtenerTodosAsync();

            var resultados = clientes
                .Select(cliente => _motorDecisiones.EvaluarCliente(cliente))
                .ToList();

            var csv = new StringBuilder();

            csv.AppendLine(
                "id_cliente,oferta_final,limite_tarjeta,monto_credito,motivo");

            foreach (var resultado in resultados)
            {
                string motivo = "\"" +
                    (resultado.Motivo ?? "").Replace("\"", "\"\"") +
                    "\"";

                csv.AppendLine(
                    $"{resultado.IdCliente}," +
                    $"{resultado.OfertaFinal}," +
                    $"{resultado.LimiteTarjeta}," +
                    $"{resultado.MontoCredito}," +
                    $"{motivo}");
            }

            byte[] archivo = new UTF8Encoding(true)
                .GetBytes(csv.ToString());

            return File(
                archivo,
                "text/csv; charset=utf-8",
                "resultado.csv");
        }

    }

}