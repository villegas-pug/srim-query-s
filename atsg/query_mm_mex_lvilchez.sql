USE SIM
GO


/*
   1. MEX sin salida
   2. FecIngreso dias transcurridos
   3. Dias perma MovMigra
   tiempo fec permanecia en adelante
*/

-- 1
DROP TABLE IF EXISTS #tmp_mex_ingr
SELECT 
   mm2.*
   INTO #tmp_mex_ingr
FROM (

   SELECT
      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      -- AND mm.sIdPaisNacionalidad = 'MEX'
      AND mm.sIdPaisNacionalidad = 'PER'

) mm2
WHERE 
   mm2.[#] = 1
   AND mm2.sTipo = 'S'
   AND mm2.sIdPaisMov = 'MEX'


-- 2
-- EXEC sp_help SimPersona
SELECT 

   mm.sIdMovMigratorio,
   mm.dFechaControl,
   mm.sTipo,
   [sCalidad] = cm.sDescripcion,
   mm.sIdPaisNacionalidad,
   mm.uIdPersona,
   [sIdDocumento(Viaje)] = mm.sIdDocumento,
   [sNumeroDoc(Viaje)] = mm.sNumeroDoc,

   p.sPaterno,
   p.sMaterno,
   p.sNombre,
   p.sSexo,
   p.dFechaNacimiento,
   p.sIdPaisNacimiento,
   p.sIdPaisNacionalidad,

   -- Aux
   [Días Transcurridos(Ingreso)] = DATEDIFF(DD, mm.dFechaControl, GETDATE()),
   [Días Permanencia(ControlMigra)] = mm.nPermanencia,
   [Días Permanencia(Exeso)] = (
                                    CASE
                                       WHEN DATEADD(DD, mm.nPermanencia, mm.dFechaControl) > GETDATE() THEN 0
                                       ELSE DATEDIFF(DD, DATEADD(DD, mm.nPermanencia, mm.dFechaControl), GETDATE())
                                    END
                              )

FROM #tmp_mex_ingr mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
ORDER BY mm.dFechaControl DESC

-- 3. Movimientos migratorios ...
-- 1
-- DROP TABLE IF EXISTS #tmp_mm_per_dest_mex
SELECT 
   pv.*
   -- INTO #tmp_mm_per_dest_mex
FROM (

   SELECT

      [Id Persona] = mm.uIdPersona,
      [Tipo Movimiento] = mm.sTipo,
      [Pais Destino] = mm.sIdPaisMov,
      [Año Control] = DATEPART(YYYY, mm.dFechaControl)

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2012-01-01 00:00:00.000'
      AND mm.sTipo = 'S'
      AND mm.sIdPaisMov = 'MEX'
      AND mm.sIdPaisNacionalidad = 'PER'

) mm2
PIVOT (
   COUNT(mm2.[Id Persona]) FOR mm2.[Año Control] IN ([2012], [2013], [2014], [2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023], [2024])
) pv



-- 4
SELECT 
   
   p.uIdPersona,
   p.sNombre,
   p.sPaterno,
   p.sMaterno,
   p.sSexo,
   p.dFechaNacimiento,
   p.sIdPaisNacimiento,
   p.sIdPaisNacionalidad

FROM SimPersona p
WHERE
   p.bActivo = 1
   AND (
            (p.sNombre LIKE '%[^a-zA-Záeéíóú.''''() ]%' AND p.sNombre NOT LIKE '%-%')
            OR (p.sPaterno LIKE '%[^a-zA-Záeéíóú.''''() ]%' AND p.sPaterno NOT LIKE '%-%')
            OR (p.sMaterno LIKE '%[^a-zA-Záeéíóú.''''() ]%' AND p.sMaterno NOT LIKE '%-%')
      )


SELECT ASCII('a')
