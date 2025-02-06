USE SIM
GO

-- 1. Número total de registros de peruanos y extranjeros 
SELECT
   [Registros (PER)] = (
                              SELECT COUNT(1)
                              FROM SimPersona p
                              WHERE 
                                 p.bActivo = 1
                                 AND p.sIdPaisNacionalidad = 'PER'
   ),
   [Registros (EXT)] = (
                              SELECT COUNT(1)
                              FROM SimPersona p
                              WHERE 
                                 p.bActivo = 1
                                 AND (p.sIdPaisNacionalidad IS NOT NULL AND p.sIdPaisNacionalidad NOT IN ('PER', 'NNN'))
   )

-- 2. Número de movimientos migraorios que se registran por dia o mes ...
SELECT pv.* 
FROM (

   SELECT
      [nAño] = DATEPART(YYYY, mm.dFechaControl),
      [nMes] = DATEPART(MONTH, mm.dFechaControl),
      mm.uIdPersona
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2020-01-01 00:00:00.000'

) mm2
PIVOT (
   COUNT(mm2.uIdPersona) FOR mm2.nMes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv


-- 3.  Número de registros de procedimientos administrativos  o servicios ...
SELECT
   [Trámite] = tt.sDescripcion,
   [Total] = COUNT(1)
FROM SImTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
GROUP BY
   tt.sDescripcion
ORDER BY 2 DESC
