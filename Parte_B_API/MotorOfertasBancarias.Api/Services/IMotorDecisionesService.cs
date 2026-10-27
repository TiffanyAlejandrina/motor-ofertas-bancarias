using MotorOfertasBancarias.Api.Models;

namespace MotorOfertasBancarias.Api.Services
{
    public interface IMotorDecisionesService
    {
        ResultadoOferta EvaluarCliente(Cliente cliente);
    }
}