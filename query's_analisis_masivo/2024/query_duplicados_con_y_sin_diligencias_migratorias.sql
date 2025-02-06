USE SIM
GO

-- 1. Limpieza de datos para eliminar la duplicidad de registros de personas idénticas sin diligencias migratorias.

-- 1.1 Guarda en `tmp` registros de personas totalmente igual.
EXEC sp_help SimPersona
DROP TABLE IF EXISTS #tmp_dupl_personas
SELECT 
   p3.*
   INTO #tmp_dupl_personas
FROM (

   SELECT
      p2.*,
      -- Aux
      [nContarDupli] = COUNT(1) OVER (PARTITION BY p2.sIdPersona)
   FROM (

      SELECT

         [sIdPersona] = REPLACE(CONCAT(pe.sNombre, pe.sPaterno, pe.sMaterno, pe.sSexo, CAST(pe.dFechaNacimiento AS FLOAT), pe.sIdPaisNacionalidad), ' ', ''),
         pe.uIdPersona,
         pe.sNombre,
         pe.sPaterno,
         pe.sMaterno,
         pe.sSexo,
         pe.dFechaNacimiento,
         pe.nIdCalidad,
         pe.sIdPaisNacionalidad,
         pe.sIdDocIdentidad,
         pe.sNumDocIdentidad,
         pe.nIdSesion
         
      FROM SimPersona pe
      WHERE
         pe.bActivo = 1
         -- AND pe.sIdPaisNacionalidad = 'PER'

   ) p2

) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_sIdPersona
   ON #tmp_dupl_personas(sIdPersona)

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_uIdPersona
   ON #tmp_dupl_personas(uIdPersona)

-- 1.2. Identifica y almacena en `tmp` los registros duplicados que tienen al menos un registro con diligencias migratorias y otro sin ellas.
DROP TABLE IF EXISTS #tmp_dupl_personas_final
SELECT f.* INTO #tmp_dupl_personas_final
FROM (
   SELECT
      pe2.*,

      -- Aux
      [nTotalDupli] = COUNT(1) OVER (PARTITION BY pe2.sIdPersona),
      [nSumar(bDiligencia)] = SUM(pe2.bDiligencia) OVER (PARTITION BY pe2.sIdPersona)
   FROM (

      SELECT
         pe.*,

         -- Aux
         [bDiligencia] = (
                        CASE
                           WHEN ( -- Control Migratorio
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimMovMigra mm
                                          WHERE 
                                             mm.bAnulado = 0
                                             AND mm.bTemporal = 0
                                             AND mm.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           WHEN ( -- Tramites
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimTramite t
                                          WHERE 
                                             t.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           WHEN ( -- Documentos
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimDocPersona dp
                                          WHERE 
                                             dp.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           WHEN ( -- Pasaportes
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimTramitePas p
                                          JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
                                          WHERE 
                                             t.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           WHEN ( -- Imagen
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimImagen i
                                          WHERE 
                                             i.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           WHEN ( -- Imagen extranjero
                                 EXISTS (
                                          SELECT TOP 1 1 FROM SimImagenExtranjero ie
                                          WHERE 
                                             ie.uIdPersona = pe.uIdPersona
                                 )
                           ) THEN 1
                           ELSE 0
                        END
         )
      FROM #tmp_dupl_personas pe

   ) pe2

) f
WHERE
   f.[nTotalDupli] > f.[nSumar(bDiligencia)]

-- 1.3. Final: Identifica y elimina los registros que no tienen diligencias migratorias.
DELETE FROM SIM.dbo.SimPersona
WHERE uIdPersona IN (
                        SELECT 
                           f.uIdPersona
                        FROM #tmp_dupl_personas_final f
                        WHERE
                           f.[bDiligencia] = 0
)


-- 1. Cantidad de control por meses AIJCH ingresos y nacionalidad
-- 2. 2023 - 2024

-- 2023
DROP TABLE IF EXISTS #tmp_mm_2023
SELECT pv.* INTO #tmp_mm_2023
FROM (
   SELECT 
      mm.sIdMovMigratorio,
      -- mm.sTipo,
      p.sNacionalidad,
      [nMesAño(Control)] = DATEPART(MM, mm.dFechaControl) -- 09-2024
   FROM SimMovMigra mm
   JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sTipo = 'E'
      AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
      AND mm.sIdDependencia = '27'
) f 
PIVOT (
   COUNT(f.sIdMovMigratorio) FOR f.[nMesAño(Control)] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 2024
DROP TABLE IF EXISTS #tmp_mm_2024
SELECT pv.* INTO #tmp_mm_2024
FROM (
   SELECT 
      mm.sIdMovMigratorio,
      -- mm.sTipo,
      p.sNacionalidad,
      [nMesAño(Control)] = DATEPART(MM, mm.dFechaControl) -- 09-2024
   FROM SimMovMigra mm
   JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sTipo = 'E'
      AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-09-23 23:59:59.999'
      AND mm.sIdDependencia = '27'
) f 
PIVOT (
   COUNT(f.sIdMovMigratorio) FOR f.[nMesAño(Control)] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- Final
SELECT *
FROM #tmp_mm_2023 a
FULL JOIN #tmp_mm_2024 b ON a.sNacionalidad = b.sNacionalidad










SELECT CONVERT(VARCHAR(7), GETDATE()) -- 09-2024

-- Test
SELECT 
   COUNT(1)
FROM SimMovMigra mm
JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND mm.sIdDependencia = '27'
   AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2024-09-23 23:59:59.999'

