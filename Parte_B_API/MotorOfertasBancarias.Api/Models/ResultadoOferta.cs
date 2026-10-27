namespace MotorOfertasBancarias.Api.Models
{
    public class ResultadoOferta
    {
        public int IdCliente { get; set; }

        public string OfertaFinal { get; set; } = string.Empty;

        public decimal LimiteTarjeta { get; set; }

        public decimal MontoCredito { get; set; }

        public string Motivo { get; set; } = string.Empty;
    }
}