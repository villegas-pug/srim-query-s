-- RC00026

--> 1. Se define como regla, que el tipo de movimiento migratorio registrado en el Control Migratorio debe coincidir con el tipo de movimiento registrado en el Itinerario.
-- ========================================================================================================================================================================

-- 1.1 `tmp` Registros de control migratorio de A.I.J.C.H
SELECT

   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.sTipo,
   mm.sIdModuloDigita,
   [dFechaControl] = CAST(mm.dFechaControl AS DATE),
   [dFechaProgramada(SimItinerario)] = CAST(i.dFechaProgramada AS DATE),
   [sNumeroNave(SimItinerario)] = i.sNumeroNave,
   [nIdTransportista(SimItinerario)] = i.nIdTransportista,
   [sTipo(SimItinerario)] = i.sTipoMovimiento

FROM SimMovMigra mm
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sTipo IN ('E', 'S') AND i.sTipoMovimiento IN ('E', 'S'))
   AND mm.sTipo != i.sTipoMovimiento -- Tipos distintos
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- ========================================================================================================================================================================