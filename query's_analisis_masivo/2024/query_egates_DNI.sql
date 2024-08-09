USE SIM
GO

/*░ 1.1

Buenos días: 
   
   → 1. Se solicita un reporte estadístico sobre las personas que han hecho uso de las E-gates utilizando un DNIe.
   → 2. Durante los últimos cinco (05) años. */

SELECT pv.* 
FROM (

   SELECT
      [nAñoControl] = DATEPART(YYYY, mm.dFechaControl),
      [sTipoMovMigra] = mm.sTipo,
      mm.sIdMovMigratorio
   FROM SimMovMigra mm
   -- JOIN SimSesion s ON mm.nIdSesion = s.nIdSesion
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      -- AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
      AND mm.sIdModuloDigita = 'EGATES' -- EGATES | EGATES
      AND mm.sIdDocumento = 'DNI'
      AND mm.sIdPaisNacionalidad = 'PER'
      AND mm.dFechaControl >= '2020-01-01 00:00:00.000'

) f
PIVOT (
   COUNT(f.sIdMovMigratorio) FOR f.nAñoControl IN ([2020], [2021], [2022], [2023], [2024])
) pv

/*░ 1.2

Buenos días: 
   
   → 1. Se solicita un reporte estadístico sobre las personas que han hecho uso en módulos convencionales utilizando un DNIe.
   → 2. Durante los últimos cinco (05) años. */

SELECT pv.* 
FROM (

   SELECT
      [nAñoControl] = DATEPART(YYYY, mm.dFechaControl),
      [sTipoMovMigra] = mm.sTipo,
      mm.sIdMovMigratorio
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      -- AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
      AND mm.sIdModuloDigita != 'EGATES' -- EGATES | EGATES
      AND mm.sIdDocumento = 'DNI'
      AND mm.sIdPaisNacionalidad = 'PER'
      AND mm.dFechaControl >= '2020-01-01 00:00:00.000'

) f
PIVOT (
   COUNT(f.sIdMovMigratorio) FOR f.nAñoControl IN ([2020], [2021], [2022], [2023], [2024])
) pv


SELECT COUNT(1)
FROM SimMovMIgra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0

SELECT COUNT(1)
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0


   SELECT COUNT(1) 
   FROM SimPersonaNoAutorizada dnv
   WHERE dnv.bActivo = 1
