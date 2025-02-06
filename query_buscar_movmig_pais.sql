USE SIM
GO


/*
   Control migratorio de ingreso a nivel nacional de personas extranjeras provenientes:
      → Trinidad y Tobago, Barbados, Granada, Santa Lucía, Guyana y San Vicente y las Granadinas.
      → Por Jefatura Zonal, Puesto de Control Migratorio, Puesto de Control Fronterizo y CEBAF.
      → Periodo  01ENE2019 AL 31DIC2023
*/

-- Flujo migratorio
-- 1
SELECT pv.* 
FROM (

   SELECT 
      mm.sIdMovMigratorio,
      [Nacionalidad] = p.sNacionalidad,
      [Dependencia] = d.sNombre,
      [Año Control] = DATEPART(YYYY, mm.dFechaControl)
   FROM SimMovMigra mm
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sTipo = 'E'
      AND mm.sIdPaisNacimiento IN ('TRI', 'BAR', 'GRA', 'SLU', 'GUY', 'SVG')
      AND mm.dFechaControl BETWEEN '2019-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

) mm2
PIVOT(
   COUNT(mm2.[sIdMovMigratorio]) FOR mm2.[Año Control] IN ([2019], [2020], [2021], [2022], [2023])
) pv

-- 2
SELECT 
   mm.sIdMovMigratorio,
   [Nacionalidad] = p.sNacionalidad,
   [Dependencia] = d.sNombre,
   [Año Control] = DATEPART(YYYY, mm.dFechaControl)
FROM SimMovMigra mm
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND mm.sIdPaisNacionalidad IN ('TRI', 'BAR', 'GRA', 'SLU', 'GUY', 'SVG')
   AND mm.dFechaControl BETWEEN '2019-01-01 00:00:00.000' AND '2024-03-26 23:59:59.999'
-- Test 
-- Trinidad y Tobago, Barbados, Granada, Santa Lucía, Guyana y San Vicente y las Granadinas.
-- TRI ↔ TRINI.TOBAG; BAR ↔ BARBADOS; GRA ↔ GRANADA; SLU ↔ SANTA LUCIA; GUY ↔ GUYANA; SVG ↔ SAN VIC.GRANA
-- 
SELECT * 
FROM  SimPais p
WHERE
   p.sNombre LIKE '%san%'

EXEC sp_help SImMovMIgra