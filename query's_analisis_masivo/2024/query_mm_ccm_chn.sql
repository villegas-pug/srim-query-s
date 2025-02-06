USE SIM
GO

USE SIM
GO

-- Años:
SELECT pv.* 
FROM (

   SELECT 
      
      mm.sIdMovMigratorio,
      [sTipoMov] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
      [nAñoMov] = DATEPART(YYYY, mm.dFechaControl)

      -- Aux
      -- [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND pe.sIdPaisNacionalidad IN ('CHN') -- CHN	| CHINA (R.P)
      AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'

) f
PIVOT (
   COUNT(f.sIdMovMigratorio) FOR f.nAñoMov IN ([2018], [2019], [2020], [2021], [2022], [2023], [2024], [2025])
) pv

-- Días:

SELECT 
   
   [dFechaControl] = CAST(mm.dFechaControl AS DATE),
   [sTipoMov] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
   [nTotal] = COUNT(1)

   -- Aux
   -- [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad IN ('CHN') -- CHN	| CHINA (R.P)
   AND mm.dFechaControl BETWEEN '2024-12-01 00:00:00.000' AND '2025-01-07 23:59:59.998'
GROUP BY
   CAST(mm.dFechaControl AS DATE),
   IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA')
ORDER BY 1 ASC


-- INM

SELECT 

   DATEPART(YYYY, t.dFechaHora), 
   [Estado Trámite] = (
                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                  ),
   COUNT(1) 

FROM SimTramite t 
INNER JOIN SimTramiteInm ti 
ON t.sNumeroTramite = ti.sNumeroTramite
WHERE 
   t.bCancelado = 0
   AND t.nIdTipoTramite = 58 -- CCM
   AND t.uIdPersona in (
                        SELECT uIdPersona 
                        FROM SimPersona 
                        WHERE sIdPaisNacionalidad = 'CHN'
)
AND DATEPART(YYYY, t.dFechaHora) >= 2018
GROUP BY 
   DATEPART(YYYY, t.dFechaHora),
   CASE ti.sEstadoActual
      WHEN 'P' THEN 'PENDIENTE'
      WHEN 'R' THEN 'ANULADO'
      WHEN 'D' THEN 'DENEGADO'
      WHEN 'A' THEN 'APROBADO'
      WHEN 'E' THEN 'DESISTIDO'
      WHEN 'B' THEN 'ABANDONO'
      WHEN 'N' THEN 'NO PRESENTADA'
   END




-- Test
SELECT * 
FROM  SimPais p
WHERE p.sNombre LIKE '%china%'





SELECT 
   DATEPART(YY,dFechaControl) AS 'AÑO', 
   sTipo AS 'TIPO', 
   COUNT(*) AS 'COUNT'
from SimMovMigra
where 
   bAnulado = 0
   AND bTemporal = 0
   AND uIdPersona in (
                        select uIdPersona 
                        from SimPersona
                        WHERE 
                           bActivo = 1
                           AND sIdPaisNacionalidad = 'CHN'
                     )
and DATEPART(YY,dFechaControl)> = 2018
GROUP BY 
   DATEPART(YY,dFechaControl),
   sTipo
ORDER BY DATEPART(YY,dFechaControl)


SELECT 
   TOP 10 mm.* 
FROM SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento = 'PAS'
   AND ISNUMERIC(mm.sNumeroDoc) = 1
   AND LEN(mm.sNumeroDoc) = 9
   AND LEN(mm.sNumeroDoc) LIKE '1[1-2]%'
   AND mm.sIdPaisNacionalidad = 'PER'
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'



SELECT TOP 10 * 
FROM SimPasaporte p
ORDER BY p.dFechaEmision DESC
   

EXEC sp_help SimUsuario
SELECT * FROM SimUsuario