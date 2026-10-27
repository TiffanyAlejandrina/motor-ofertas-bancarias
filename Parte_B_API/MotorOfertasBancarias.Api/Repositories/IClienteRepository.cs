using MotorOfertasBancarias.Api.Models;

namespace MotorOfertasBancarias.Api.Repositories
{
    public interface IClienteRepository
    {
        Task<List<Cliente>> ObtenerTodosAsync();

        Task<Cliente?> ObtenerPorIdAsync(int idCliente);
    }
}