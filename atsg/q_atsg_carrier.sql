USE SIM
GO

CREATE SYNONYM SimCarrierCode FOR BD_SIRIM.dbo.CarrierCode

-- DROP TABLE BD_SIRIM.dbo.CarrierCode

SELECT t.*
FROM SimEmpTransporte t

--> 2
SELECT
   e2.*
FROM (

   SELECT 
      e.nIdTransportista,
      e.sNombreRazon,
      [nCoincidencias] = (
                           SELECT COUNT(1)
                           FROM SimCarrierCode c
                           WHERE 
                              c.Active = 1
                              AND c.Code = e.sCodAnterior
      )
   FROM SimEmpTransporte e
   WHERE
      e.bActivo = 1
      AND e.sIdViaTransporte = 'A'
   -- ORDER BY [nCoincidencias] DESC

) e2
WHERE
   e2.nCoincidencias = 0
   AND NOT EXISTS (
      SELECT TOP 1 1
      FROM SimMovMigra mm WHERE mm.nIdTransportista = e2.nIdTransportista
      AND 
         mm.bAnulado = 0 AND mm.bTemporal = 0
         AND mm.dFechaControl >= '2023-01-01 00:00:00.000'
   )


--> Agrupa Transportista en `SimMovMigra` ...
-- 1
DROP TABLE IF EXISTS #tmp_mm_transportista
SELECT 
   mm.nIdTransportista,
   t.sNombreRazon,
   t.sCodAnterior,
   [nTotal] = COUNT(1)
   INTO #tmp_mm_transportista
FROM SimMovMigra mm
JOIN SimEmpTransporte t ON mm.nIdTransportista = t.nIdTransportista
WHERE 
   mm.bAnulado = 0 AND mm.bTemporal = 0
   AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
   AND mm.sIdViaTransporte = 'A'  -- A | AEREO
GROUP BY
   mm.nIdTransportista,
   t.sNombreRazon,
   t.sCodAnterior

-- 2
SELECT 
   t.nIdTransportista, t.sNombreRazon
FROM (

   SELECT 
      DISTINCT mm.nIdTransportista
   FROM SimMovMigra mm
   WHERE 
      mm.bAnulado = 0 AND mm.bTemporal = 0
      AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

) mm2 JOIN SimEmpTransporte t ON mm2.nIdTransportista = t.nIdTransportista
WHERE
   t.sIdViaTransporte = 'A'  -- A | AEREO


--> Final
-- 1
SELECT 
   TOP 100
   [sCodAnterior(Sim)] = e.sCodAnterior,
   [sNombreRazon(Sim)] = e.sNombreRazon,
   [Name(ATSG)] = c.Name,
   [Code(ATSG)] = c.Code
FROM SimEmpTransporte e
JOIN SimCarrierCode c ON e.sCodAnterior = c.Code
WHERE
   e.bActivo = 1 AND c.Active = 1
   AND e.sIdViaTransporte = 'A'

-- 2
SELECT 
   [sCodAnterior(Sim)] = e.sCodAnterior,
   [sNombreRazon(Sim)] = e.sNombreRazon,
   [Code(ATSG)] = c.Code,
   [Name(ATSG)] = c.Name
FROM #tmp_mm_transportista e
LEFT JOIN SimCarrierCode c ON e.sCodAnterior = c.Code
WHERE
   c.Active = 1


/*
AI	AIR CANADA	AI	AIR INDIA
AL	AIR PLUS	AL	SKYWAY AIRLINES DBA MIDWEST CONNECT
AM	AMERICANA	AM	AEROMEXICO
*/

SELECT * 
FROM SimEmpTransporte t
WHERE
   t.sNombreRazon = 'AIR CANADA'

SELECT * 
FROM SimCarrierCode c ORDER BY c.Name

