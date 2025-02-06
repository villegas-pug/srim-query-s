USE BD_SIRIM
GO

--> 1. Personas duplicadas
-- ============================================================================================================================================================
-- ============================================================================================================================================================

--> 2. Personas duplicadas en movimientos migratorios
-- ============================================================================================================================================================

-- 2.1 Personas duplicadas con movimientos migratorios.
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
         pe.nIdCalidad,
         [sCalidad] = cm.sDescripcion
         
      FROM SIM.dbo.SimPersona pe
      JOIN SIM.dbo.SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
      WHERE
         pe.bActivo = 1

   ) p2

) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_sIdPersona
   ON #tmp_dupl_personas(sIdPersona)

-- 2.2 Registran control migratorio
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

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_mm 
   ON #tmp_dupl_personas_mm(uIdPersona)

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_mm_sIdPersona
   ON #tmp_dupl_personas_mm(sIdPersona)

-- 2.3 Personas únicas
DROP TABLE IF EXISTS #tmp_dupl_personas_mm_per_uniq
SELECT f.* INTO #tmp_dupl_personas_mm_per_uniq
FROM (

   SELECT
      mm.sIdMovMigratorio,
      d.uIdPersona,
      d.sIdPersona,
      [##] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM #tmp_dupl_personas_mm d
   JOIN SIM.dbo.SimMovMigra mm ON d.uIdPersona = mm.uIdPersona

) f
WHERE f.[##] = 1

-- 2.4 Final
SELECT 
   f.sIdMovMigratorio,
   [jDatosDuplicados] = (

         SELECT 
               [Id Persona] = d.uIdPersona,
               [Nombre] = d.sNombre,
               [Paterno] = d.sPaterno,
               [Materno] = d.sMaterno,
               [Sexo] = d.sSexo,
               [Fecha Nacimiento] = d.dFechaNacimiento,
               [Pais Nacionalidad] = d.sIdPaisNacionalidad,
               [Doc Identidad] = d.sIdDocIdentidad,
               [Num Doc Identidad] = d.sNumDocIdentidad,
               [Id Calidad] = d.nIdCalidad,
               [Calidad] = d.sCalidad
         FROM #tmp_dupl_personas_mm d
         WHERE 
            d.sIdPersona = f.sIdPersona
         FOR JSON PATH, ROOT('SimPersona')
   )
   -->tmp
FROM #tmp_dupl_personas_mm_per_uniq f


-- Test
SELECT JSON_QUERY(
   (
      SELECT * 
      FROM RimRNDimension
      FOR JSON PATH, ROOT('SimPersona')
   ),
   '$.SimPerson'
)



--> 3. Movimientos migratorios duplicadas: 
-- ============================================================================================================================================================

UPDATE RimRNControlCambios
   SET sScript = '
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
         [sIdPersona] = REPLACE(CONCAT(pe.sNombre, pe.sPaterno, pe.sMaterno, pe.sSexo, CAST(pe.dFechaNacimiento AS FLOAT), pe.sIdPaisNacionalidad), '' '', ''''),
         [uIdPersona] = pe.uIdPersona,
         [sNombre] = COALESCE(pe.sNombre, ''-''),
         [sPaterno] = COALESCE(pe.sPaterno, ''-''),
         [sMaterno] = COALESCE(pe.sMaterno, ''-''),
         [sSexo] = COALESCE(pe.sSexo, ''-''),
         [dFechaNacimiento] = COALESCE(pe.dFechaNacimiento, ''-''),
         [sIdPaisNacionalidad] = COALESCE(pe.sIdPaisNacionalidad, ''-''),
         [sIdDocIdentidad] = COALESCE(pe.sIdDocIdentidad, ''-''),
         [sNumDocIdentidad] = COALESCE(pe.sNumDocIdentidad, ''-''),
         pe.nIdCalidad,
         [sCalidad] = cm.sDescripcion
      FROM SIM.dbo.SimPersona pe
      JOIN SIM.dbo.SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
      WHERE
         pe.bActivo = 1
   ) p2
) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_sIdPersona ON #tmp_dupl_personas(sIdPersona)

-- 2.2 Registran control migratorio
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

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_mm ON #tmp_dupl_personas_mm(uIdPersona)
CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_mm_sIdPersona ON #tmp_dupl_personas_mm(sIdPersona)

-- 2.3 Personas únicas
DROP TABLE IF EXISTS #tmp_dupl_personas_mm_per_uniq
SELECT f.* INTO #tmp_dupl_personas_mm_per_uniq
FROM (
   SELECT
      mm.sIdMovMigratorio,
      d.uIdPersona,
      d.sIdPersona,
      [##] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM #tmp_dupl_personas_mm d
   JOIN SIM.dbo.SimMovMigra mm ON d.uIdPersona = mm.uIdPersona

) f
WHERE f.[##] = 1
-- 2.4 Final
SELECT 
   f.sIdMovMigratorio,
   [jDatosDuplicados] = (

         SELECT 
               [Id Persona] = d.uIdPersona,
               [Nombre] = d.sNombre,
               [Paterno] = d.sPaterno,
               [Materno] = d.sMaterno,
               [Sexo] = d.sSexo,
               [Fecha Nacimiento] = d.dFechaNacimiento,
               [Pais Nacionalidad] = d.sIdPaisNacionalidad,
               [Doc Identidad] = d.sIdDocIdentidad,
               [Num Doc Identidad] = d.sNumDocIdentidad,
               [Id Calidad] = d.nIdCalidad,
               [Calidad] = d.sCalidad
         FROM #tmp_dupl_personas_mm d
         WHERE 
            d.sIdPersona = f.sIdPersona
         FOR JSON PATH, ROOT(''SimPersona'')
   )
   -->tmp
FROM #tmp_dupl_personas_mm_per_uniq f
   '
WHERE sIdRN = 'RN00189'


-- 1
DROP TABLE IF EXISTS #tmp
SELECT
   mm2.*
   INTO #tmp
FROM (

   SELECT 
      -- Control
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdPaisNacionalidad,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.sIdPaisMov,

      -- Persona
      pe.sNombre,
      pe.sPaterno,
      pe.sMaterno,
      pe.sSexo,
      pe.dFechaNacimiento,

      -- Aux
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY 
                                       mm.uIdPersona, 
                                       mm.sTipo, 
                                       CONVERT(VARCHAR(16), mm.dFechaControl, 120)
                                 ) -- yyyy-MM-dd HH:mm
   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) mm2
WHERE
   mm2.nDupl BETWEEN 2 AND 3

CREATE NONCLUSTERED INDEX ix_tmp_uIdPersona 
   ON #tmp(uIdPersona)

-- 2
DROP TABLE IF EXISTS #tmp2
SELECT * INTO #tmp2
FROM (

   SELECT
      d.uIdPersona,
      d.sIdMovMigratorio,
      [#] = ROW_NUMBER() OVER (PARTITION BY d.uIdPersona ORDER BY d.sIdMovMigratorio ASC)
   FROM #tmp d

) f
WHERE
   f.[#] = 1

CREATE NONCLUSTERED INDEX ix_tmp2_uIdPersona_sIdMovMigratorio
   ON #tmp2(uIdPersona, sIdMovMigratorio)

SELECT
   f.sIdMovMigratorio,
   [jDatosDuplicados] = (
                           SELECT * 
                           FROM #tmp d
                           WHERE 
                              d.uIdPersona = f.uIdPersona
                           FOR JSON PATH, ROOT('SimMovMigra')
   )
   -->tmp
FROM #tmp2 f


-- Update
UPDATE RimReglaNegocio
   SET nIdStatusRegla = 2
FROM RimReglaNegocio r
JOIN RimRNControlCambios c ON r.sIdRN = c.sIdRN
JOIN RimRNRegistroEjecucionScript e ON c.nIdRNControlCambio = e.nIdRNControlCambio
WHERE
   e.nResultado > 0


--> 4. Peruanos duplicados:
-- ============================================================================================================================================================

-- 4.1 Personas duplicadas con movimientos migratorios.
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
         AND pe.sIdPaisNacionalidad = 'PER'

   ) p2

) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE NONCLUSTERED INDEX ix_tmp_dupl_personas_sIdPersona
   ON #tmp_dupl_personas(sIdPersona)

SELECT COUNT(1) 
FROM (
   SELECT
      d.sIdPersona,
      [nDuplicados] = COUNT(1)
   FROM #tmp_dupl_personas d
   GROUP BY
      d.sIdPersona
) f
WHERE
   f.nDuplicados = 2



-- Final
-- 2 | 396,055
SELECT 
   f.nDuplicados,
   [nPersonas] = COUNT(1)
FROM (
   SELECT
      d.sIdPersona,
      [nDuplicados] = COUNT(1)
   FROM #tmp_dupl_personas d
   GROUP BY
      d.sIdPersona
) f
GROUP BY
   f.nDuplicados
ORDER BY 2 DESC

-- 5. Movimientos duplicados.

-- 5.1
SELECT COUNT(1)
FROM #tmp ;
DROP TABLE IF EXISTS #tmp
SELECT
   mm2.*
   INTO #tmp
FROM (

   SELECT 
      -- Aux
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY 
                                       mm.uIdPersona, 
                                       mm.sTipo, 
                                       CONVERT(VARCHAR(16), mm.dFechaControl, 120)
                                 ) -- yyyy-MM-dd HH:mm
   FROM SIM.dbo.SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) mm2
WHERE
   mm2.nDupl >= 2

-- 5.2 Final
SELECT COUNT(1) FROM #tmp


-- 6. DNI vincualdos a multipls persona.


-- 6.1
SELECT * INTO #tmp_dni_uniq
FROM (
   SELECT
      dp.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY dp.uIdPersona ORDER BY dp.dFechaHoraAud DESC)
   FROM SIM.dbo.SimDocPersona dp
   JOIN SIM.dbo.SimPersona pe ON dp.uIdPersona = pe.uIdPersona
   WHERE 
      dp.bActivo = 1
      AND pe.sIdPaisNacionalidad = 'PER'
      AND dp.sIdDocumento = 'DNI'
      AND ISNUMERIC(dp.sNumero) = 1
      AND LEN(dp.sNumero) = 8
) f
WHERE f.[#] = 1


-- 6.2
SELECT TOP 1 * FROM SIM.dbo.SimDocPersona

SELECT f.* INTO #tmp_dni_uniq_f 
FROM (
   SELECT 
      u.*,
      [##] = COUNT(1) OVER (PARTITION BY u.sNumero),
      [###] = COUNT(1) OVER (PARTITION BY u.uIdPersona)
   FROM #tmp_dni_uniq u
) f
WHERE 
   f.## >= 2 
   AND f.### = 1

-- Final

-- 1
SELECT
   f2.nDoc,
   [nPersona] = COUNT(1)
FROM (

   SELECT 
      f.sNumero,
      [nDoc] = COUNT(1)
   FROM #tmp_dni_uniq_f f
   GROUP BY
      f.sNumero

) f2
GROUP BY
   f2.nDoc

-- 2
SELECT TOP 10 * FROM #tmp_dni_uniq_f f
ORDER BY f.sNumero DESC


SELECT * FROM SIM.dbo.SimLugarEntrega
SELECT COUNT(1) FROM SIM.dbo.SimLugarEntrega