-- RC00059

-- 8. Se define como regla, que todos los itinerarios en estado cerrado o programado deben tener al menos un pasajero.
-- =====================================================================================================================================================================

SELECT TOP 10 * FROM SimMovMigra mm
ORDER BY mm.dFechaControl DESC

/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

-- 8.1
SELECT

   [Id Itinerario] = i.sIdItinerario,
   [Fecha Control] = i.dFechaProgramada,
   [Número Nave] = i.sNumeroNave,
   [Empresa Transporte] = e.sNombreRazon,
   [Tipo Movimiento] = i.sTipoMovimiento,
   [Estado Itinerario] = (
                              CASE
                                 WHEN (i.sEstado = 'X') THEN 'Cancelado'
                                 WHEN (i.sEstado = 'N') THEN 'Anulado'
                                 WHEN (i.sEstado = 'Z') THEN 'Cancelado Automático'
                                 WHEN (i.sEstado = 'C') THEN 'Cerrado'
                                 WHEN (i.sEstado = 'A') THEN 'Programado'
                              END
                        ),
   [Cantidad Mov] = i.nCantidadMov

FROM SimItinerario i
JOIN SimEmpTransporte e ON i.nIdTransportista = e.nIdTransportista
WHERE
   i.sEstado IN ('C', 'A')
   AND i.dFechaProgramada >= '2016-01-01 00:00:00.000'
   AND i.nCantidadMov = 0


-- =====================================================================================================================================================================