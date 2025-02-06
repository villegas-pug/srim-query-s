--> 1. ...
-- =================================================================================================================================

CREATE OR ALTER PROCEDURE usp_Rim_RN_GenerarIdReglaNegocio
AS
BEGIN
      SELECT 
         [newIdRN] = CONCAT('RN', FORMAT(MAX(RIGHT(r.sIdRN, 5)) + 1, '00000'))
      FROM RimReglaNegocio r
END

-- Test
EXEC usp_Rim_RN_GenerarIdReglaNegocio

SELECT * FROM RimRNTipoScript

SELECT * FROM RimRNControlCambios c
WHERE c.sIdRN = 'RN00216'

SELECT * FROM RimRNStatus
EXEC sp_help RimReglaNegocio
EXEC sp_help RimRNControlCambios

-- ================================================================================================================================================



-- RUSIA | CUBA | VENEZUELA

SELECT * 
FROM SIM.dbo.SimPais p
WHERE
   p.sNombre IN ('RUSIA', 'CUBA', 'VENEZUELA')

-- CUB | RUS | VEN
SELECT pv.* 
FROM (
   SELECT 
      mm.sIdMovMigratorio,
      mm.sTipo,
      mm.sIdPaisNacionalidad
   FROM SIM.dbo.SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad IN ('CUB', 'RUS', 'VEN')
      AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2024-08-31 23:59:59.999'
) f
PIVOT (
   count(f.sIdMovMigratorio) FOR f.sTipo IN ([E], [S])
) pv