using MotorOfertasBancarias.Api.Models;

namespace MotorOfertasBancarias.Api.Services
{
    public class MotorDecisionesService : IMotorDecisionesService
    {
        public ResultadoOferta EvaluarCliente(Cliente cliente)
        {
            if (cliente == null)
                throw new ArgumentNullException(nameof(cliente));

            var resultado = new ResultadoOferta
            {
                IdCliente = cliente.IdCliente ?? 0,
                OfertaFinal = "RECHAZADO",
                LimiteTarjeta = 0,
                MontoCredito = 0
            };

            // 1. Validar calidad de los datos
            if (cliente.EstadoValidacion != "VALIDO"
                || !cliente.IdCliente.HasValue
                || !cliente.Edad.HasValue
                || !cliente.IngresoMensual.HasValue
                || !cliente.IndiceConfiabilidad.HasValue
                || !cliente.PagoMensualDeudas.HasValue
                || !cliente.DiasAtrasoMaximo.HasValue)
            {
                resultado.OfertaFinal = "REQUIERE_REVISION";
                resultado.Motivo = "Datos incompletos o invalidos";
                return resultado;
            }

            int edad = cliente.Edad.Value;
            decimal ingreso = cliente.IngresoMensual.Value;
            decimal indice = cliente.IndiceConfiabilidad.Value;
            decimal deuda = cliente.PagoMensualDeudas.Value;
            int atraso = cliente.DiasAtrasoMaximo.Value;

            // 2. Aplicar reglas de rechazo
            if (indice < 500)
                return Rechazar(resultado, "Indice de confiabilidad menor a 500");

            if (atraso > 60)
                return Rechazar(resultado, "Atraso mayor a 60 dias");

            if (edad < 21 || edad > 70)
                return Rechazar(resultado, "Edad fuera del rango permitido");

            if (ingreso < 3000)
                return Rechazar(resultado, "Ingreso mensual menor a Q3000");

            decimal porcentajeDeuda = deuda / ingreso;

            if (porcentajeDeuda > 0.45m)
                return Rechazar(resultado, "Relacion deuda ingreso mayor al 45%");

            // 3. Calcular capacidad de pago
            decimal capacidad = Math.Max(
                0m,
                ingreso * 0.40m - deuda
            );

            // 4. Determinar oferta según confiabilidad
            if (indice < 650)
            {
                resultado.OfertaFinal = "TARJETA";
                resultado.LimiteTarjeta =
                    CalcularMonto(capacidad * 3m, 20000m);
            }
            else if (indice < 800)
            {
                if (porcentajeDeuda <= 0.30m)
                {
                    resultado.OfertaFinal = "COMBINADO";
                    resultado.LimiteTarjeta =
                        CalcularMonto(capacidad * 3m, 40000m);
                    resultado.MontoCredito =
                        CalcularMonto(capacidad * 24m, 150000m);
                }
                else
                {
                    resultado.OfertaFinal = "TARJETA";
                    resultado.LimiteTarjeta =
                        CalcularMonto(capacidad * 4m, 40000m);
                }
            }
            else
            {
                if (porcentajeDeuda <= 0.30m)
                {
                    resultado.OfertaFinal = "COMBINADO";
                    resultado.LimiteTarjeta =
                        CalcularMonto(capacidad * 4m, 80000m);
                    resultado.MontoCredito =
                        CalcularMonto(capacidad * 36m, 250000m);
                }
                else
                {
                    resultado.OfertaFinal = "CREDITO";
                    resultado.MontoCredito =
                        CalcularMonto(capacidad * 36m, 250000m);
                }
            }

            resultado.Motivo = "Cumple las reglas de evaluacion";
            return resultado;
        }

        private static ResultadoOferta Rechazar(
            ResultadoOferta resultado,
            string motivo)
        {
            resultado.OfertaFinal = "RECHAZADO";
            resultado.Motivo = motivo;
            return resultado;
        }

        private static decimal CalcularMonto(
            decimal monto,
            decimal tope)
        {
            decimal montoLimitado = Math.Min(
                Math.Max(0m, monto),
                tope
            );

            return Math.Round(
                montoLimitado / 100m,
                0,
                MidpointRounding.AwayFromZero
            ) * 100m;
        }
    }
}