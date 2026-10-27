namespace MotorOfertasBancarias.Api.Models
{
    public class Cliente
    {
        public int? IdCliente { get; set; }
        public int? Edad { get; set; }
        public decimal? IngresoMensual { get; set; }
        public decimal? IndiceConfiabilidad { get; set; }
        public int? MesesEnEmpleo { get; set; }
        public int? ProductosContratados { get; set; }
        public decimal? PagoMensualDeudas { get; set; }
        public int? DiasAtrasoMaximo { get; set; }
        public string? ProductoSolicitado { get; set; }
        public decimal? MontoSolicitado { get; set; }
        public string? Departamento { get; set; }
        public string? Canal { get; set; }
        public string? EstadoValidacion { get; set; }
    }
}