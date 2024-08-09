USE SIM
GO

-- ================================================================ ::. PASAPORTES CONSULARES ::. ===========================================================================

/*
   Caracteristicas:
      a. bConsular: 1
      b. No tiene asociado un trámite.

*/

-- 1
EXEC sp_help SimPasaporte
DROP TABLE IF EXISTS #tmp_pas_consulares
SELECT 
   p.*
   INTO #tmp_pas_consulares
FROM SimPasaporte P
WHERE
   p.bConsular = 1
   AND p.sEstadoActual = 'E'

-- 2
SELECT

   TOP 10
   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.sTipo,
   [sNombres(SimMovMigra)] = mm.sNombres,
   [sIdDocumento(SimMovMigra)] = mm.sIdDocumento,
   [sNumeroDoc(SimMovMigra)] = mm.sNumeroDoc,

   [sNombres(SimPasaporte)] = CONCAT(c.sNombre, ', ', c.sPaterno, ' ', c.sMaterno),
   [sNumeroDoc(SimPasaporte)] = c.sPasNumero

FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN #tmp_pas_consulares c ON mm.sIdDocumento = 'PAS'
                              AND mm.sNumeroDoc = c.sPasNumero
                              AND mm.sIdPaisNacimiento = c.sIdPaisNacimiento
                              AND pe.dFechaNacimiento = c.dFechaNacimiento
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND mm.sIdPaisNacimiento != 'NNN'
ORDER BY
   mm.dFechaControl DESC

-- =====================================================================================================================================================================

