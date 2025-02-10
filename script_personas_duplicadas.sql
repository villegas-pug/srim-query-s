--> 1. Duplicidad de registro de identidad.
-- ============================================================================================================================================================

-- 1.1 Personas duplicadas:
-- EXEC sp_help SimPersona
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
         [uIdPersona] = pe.uIdPersona,
         [sNombre] = COALESCE(pe.sNombre, '-'),
         [sPaterno] = COALESCE(pe.sPaterno, '-'),
         [sMaterno] = COALESCE(pe.sMaterno, '-'),
         [sSexo] = COALESCE(pe.sSexo, '-'),
         [dFechaNacimiento] = COALESCE(pe.dFechaNacimiento, '-'),
         [sIdPaisNacionalidad] = COALESCE(pe.sIdPaisNacionalidad, '-'),
         [sIdDocIdentidad] = COALESCE(pe.sIdDocIdentidad, '-'),
         [sNumDocIdentidad] = COALESCE(pe.sNumDocIdentidad, '-'),
         pe.nIdCalidad
         
      FROM SIM.dbo.SimPersona pe
      WHERE
         pe.bActivo = 1

   ) p2

) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_sIdPersona
   ON #tmp_dupl_personas(sIdPersona)

-- 1.2 Final: Registran control migratorio
DROP TABLE IF EXISTS #tmp_dupl_personas_mm
SELECT f.* INTO #tmp_dupl_personas_mm
FROM (

   SELECT 
      d.*,
      [#] = COUNT(1) OVER (PARTITION BY d.sIdPersona)
   FROM #tmp_dupl_personas d
   WHERE EXISTS (
                  SELECT TOP 1 1 FROM 
                  SIM.dbo.SimMovMigra mm
                  WHERE 
                     mm.bAnulado = 0
                     AND mm.bTemporal = 0
                     AND mm.uIdPersona = d.uIdPersona
            )

) f
WHERE f.[#] >= 2