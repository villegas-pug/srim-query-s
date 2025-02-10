-- RC00063

-- 3. Se define como regla de calidad que la fecha programada del itinerario debe ser coherente y no debe exceder significativamente la fecha actual.
-- =====================================================================================================================================================================

-- 2.1
/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

SELECT

   [Id Persona] = '',
   [Nombres] = '',
   [Apellido 1] = '',
   [Apellido 2] = '',
   [Sexo] = '',
   [Fecha Nacimiento] = '',
   [Nacionalidad] = '',

   -- Aux
   [Id Itinerario] = i.sIdItinerario,
   [Fecha Programada] = i.dFechaProgramada,
   [Estado] = CASE
                  WHEN i.sEstado = 'C' THEN 'Cerrado'
                  WHEN i.sEstado = 'A' THEN 'Programado'
              END,
   [Tipo Movimiento] = i.sTipoMovimiento,
   [Cantidad Movimiento] = i.nCantidadMov
   
FROM SIM.dbo.SimItinerario i 
WHERE
   i.sEstado IN ('A', 'C')
   AND i.dFechaProgramada > GETDATE()
   /* AND EXISTS ( -- Registros de control asociados
               SELECT TOP 1 1
               FROM SimMovMigra mm
               WHERE 
                  mm.bAnulado = 0
                  AND mm.bTemporal = 0
                  AND mm.sIdItinerario = i.sIdItinerario
   ) */


-- =====================================================================================================================================================================
