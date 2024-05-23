USE SIM
GO

/*
-- ==================================================================================================================================== */

/*» Tipos de Calidad Migratoria
   R → Residente
   T → Temporal
   N → (PTP, CPP, CPP-RS109) */

SELECT TOP 10 * FROM SIM.dbo.xTotalExtranjerosPeru

-- 1. Residentes con el tipo de Calidad `T` → Temporal ...
-- 458,236
SELECT 
   -- 1
   [Id Persona] = e.uIdPersona,
   [Nombres] = e.Nombre,
   [Apellido 1] = e.Paterno,
   [Apellido 2] = e.Materno,
   [Sexo] = e.Sexo,
   [Fecha Nacimiento] = e.FechaNacimiento,
   [Nacionalidad] = e.Nacionalidad,

   -- Aux
   [Tipo Calidad Migratoria] = (
                                    SELECT scm.sTipo FROM SimPersona sper 
                                    JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
                                    WHERE
                                       sper.uIdPersona = e.uIdPersona
                                 ),
   [Calidad Migratoria] = (
                              SELECT scm.sDescripcion FROM SimPersona sper 
                              JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
                              WHERE
                                 sper.uIdPersona = e.uIdPersona
                           )
FROM SIM.dbo.xTotalExtranjerosPeru e
WHERE
   -- e.uIdPersona = '00000000-0000-0000-0000-000000000000'
   -- AND e.CalidadTipo IN ('N', 'R')
   e.CalidadTipo = 'R'
   AND EXISTS (-- ...

      SELECT 1 FROM SimPersona sper
      JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
      WHERE
         sper.uIdPersona = e.uIdPersona
         AND scm.sTipo = 'T'
   )
   AND NOT EXISTS (

      SELECT 1 FROM SimTramite st
      JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
      WHERE
         st.bCancelado = 0
         AND st.uIdPersona = e.uIdPersona
         -- 45 ↔ CANC. PERMANENCIA/RESIDENCIA X OFICIO
         -- 66  ↔ CANCE.RESIDENCIA Y SALIDA DEF.
         -- 116 ↔ CANCELACIÓN CALIDAD MIGRATORIA Y PERMISO TEMPORAL
         AND st.nIdTipoTramite IN (45, 66, 116)
         AND sti.sEstadoActual = 'A'

   )
   AND EXISTS ( -- Trámites otorgan la residencia ... 

      SELECT t.* FROM (
         SELECT 
            sti.sEstadoActual,
            [nOrden] = ROW_NUMBER() OVER (ORDER BY st.dFechaHora DESC)
         FROM SimTramite st
         JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
         WHERE
            st.bCancelado = 0
            AND st.uIdPersona = e.uIdPersona
            -- 57 | PRORROGA DE RESIDENCIA
            -- 58 | CAMBIO DE CALIDAD MIGRATORIA
            -- 113 | REGULARIZACION DE EXTRANJEROS
            -- 126 | PERMISO TEMPORAL DE PERMANENCIA - RS109
            AND st.nIdTipoTramite IN (57, 58, 113, 126)
      ) t
      WHERE
         t.nOrden = 1
         AND t.sEstadoActual = 'A'

   )


-- 2. Extranjeros con calidad migratoria PERUANO sin trámites de Nacionalización ...
SELECT
   -- 1
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,
   [Nacionalidad] = sPer.sIdPaisNacionalidad,

   -- Aux
   [Tipo Calidad Migratoria] = scm.sTipo,
   [Calidad Migratoria] = scm.sDescripcion

FROM SimPersona sper
JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
WHERE
   sper.bActivo = 1
   AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND sper.nIdCalidad = 21 -- 21 | PERUANO | N
   AND (sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND sper.sIdPaisNacionalidad IS NOT NULL)
   AND (sper.sIdPaisNacimiento NOT IN ('PER', 'NNN') AND sper.sIdPaisNacimiento IS NOT NULL)
   -- AND sper.sIdDocIdentidad NOT IN ('DNI', 'PAS', 'LE', 'PNA', 'SLV', 'LIB')
   AND sper.sIdDocIdentidad IN ('CIP')
   /* AND sper.sIdDocIdentidad != ALL (
                                       SELECT docs.[value] FROM STRING_SPLIT(
                                          (
                                             SELECT t.sDocumentos FROM (
                                                VALUES
                                                   ('ARN, ESP', 'NNN|PAS|LE|PNA|SLV|LIB'),
                                                   ('OTROS', 'NNN|DNI|PAS|LE|PNA|SLV|LIB')
                                             ) AS t([sId], [sDocumentos])
                                             WHERE
                                                t.sId LIKE (
                                                      CASE
                                                         WHEN sper.sIdPaisNacionalidad NOT IN ('ARN', 'ESP') THEN 'OTROS'
                                                         ELSE '%' + sper.sIdPaisNacionalidad + '%'
                                                      END
                                                )
                                          ), '|'
                                       ) AS docs

                                    ) */
   -- AND (sper.sNumDocIdentidad != '' AND sper.sNumDocIdentidad IS NOT NULL)
   AND NOT EXISTS (
      SELECT 1 FROM SimTituloNacionalidad stn
      WHERE
         stn.bAnulado = 0
         AND stn.uIdPersona = sper.uIdPersona
   )

SELECT TOP 10 * FROM SimDocumento sd WHERE sd.sIdDocumento LIKE '%CIP%'


-- 3. Extranjero con documento de viaje `CIP` y calidad migratoria PERUANO en SimMovMigra ...
-- CIP | 6233
-- PAS | 4144
SELECT
   -- 1
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,
   [Nacionalidad] = smm.sIdPaisNacionalidad,

   -- Aux
   [Id Movimiento Migratorio] = smm.sIdMovMigratorio,
   [Calidad Migratoria] = scm.sDescripcion

FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND smm.nIdCalidad = 21 -- 21 | PERUANO | N
   AND (smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND smm.sIdPaisNacionalidad IS NOT NULL)
   -- AND (smm.sIdPaisNacimiento NOT IN ('PER', 'NNN') AND smm.sIdPaisNacimiento IS NOT NULL)
   AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND smm.sIdDocumento = 'CIP' --  Cédula de Identidad Personal
   AND (smm.sNumeroDoc != '' AND smm.sNumeroDoc IS NOT NULL)


-- 4. Tipo de calidad `Temporal` con 0 días de permanencia en Control Migratorio ...
SELECT
   
   -- 1
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,
   [Nacionalidad] = smm.sIdPaisNacionalidad,

   -- Aux
   [Id Movimiento Migratorio] = smm.sIdMovMigratorio,
   [Tipo Movimiento] = smm.sTipo,
   [Calidad Migratoria] = scm.sDescripcion,
   [Permanencia] = smm.nPermanencia

FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND smm.sTipo = 'E'
   AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
   -- AND smm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-01-31 23:59:59.999'
   AND (smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND smm.sIdPaisNacionalidad IS NOT NULL)
   AND scm.sTipo = 'T' -- Temporanl
   -- AND scm.nIdCalidad NOT IN (288, 317) -- 288 ↔ ESPECIAL; 317 ↔ ESPECIAL
   AND scm.nIdCalidad IN (40, 41, 106, 227) -- TURISTA
   AND (smm.nPermanencia = 0 OR smm.nPermanencia = '' OR smm.nPermanencia IS NULL)


-- 5. Peruanos con Carnet de Extranjería ...
-- 5.1
DROP TABLE IF EXISTS #tmp_simperuano
SELECT p.* INTO #tmp_simperuano FROM (

   SELECT 
      sper.*,
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY
                                       SOUNDEX(sper.sNombre),
                                       sper.sPaterno,
                                       sper.sMaterno,
                                       sper.sSexo,
                                       sper.dFechaNacimiento,
                                       sper.sIdPaisNacimiento
                                       -- sper.sIdPaisResidencia,
                                       -- sper.sIdPaisNacionalidad
                              )
   FROM SimPersona sper
   WHERE
      sper.bActivo = 1
      AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sper.sIdPaisNacimiento = 'PER'
      AND sper.sIdDocIdentidad IN ('DNI', 'PAS', 'LE', 'PNA', 'SLV', 'LIB')
      -- AND (LEN(sper.sNumDocIdentidad) > 0 AND sper.sNumDocIdentidad IS NOT NULL)

) p
WHERE
   p.nDupl >= 2

-- 5.2 Peruanos con carnet de extranjeria ...
DROP TABLE IF EXISTS #tmp_simperuano_con_ce
SELECT p.* INTO #tmp_simperuano_con_ce FROM #tmp_simperuano p
WHERE 
   p.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   AND EXISTS (

      SELECT 1 FROM SIM.dbo.xTotalExtranjerosPeru e
      WHERE
         e.uIdPersona = p.uIdPersona
         -- AND e.CalidadTipo IN ('N', 'R')
         AND e.CalidadTipo IN ('R')

   )

-- 5.3 Final
SELECT
   
   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- Aux
   [Tipo Calidad Migratoria] = scm.sTipo,
   [Calidad Migratoria] = scm.sDescripcion

FROM #tmp_simperuano_con_ce p
LEFT JOIN SimCalidadMigratoria scm ON p.nIdCalidad = scm.nIdCalidad
WHERE
   scm.sTipo = 'R'


-- Test ...
EXEC sp_help SImMovMIgra
SELECT * FROM #tmp_simperuano_con_ce

-- ======================================================================================================================================================
