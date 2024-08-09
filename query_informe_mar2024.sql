USE SIM
GO

-- 1. Calidad solicitada `TRABAJADOR`, no registra Empresa ...
-- ======================================================================================================================================================================== */

-- 1.1
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Tramite] = tt.sDescripcion,
   [Estado Trámite] = ti.sEstadoActual,
   [Calidad Migratoria] = cm.sDescripcion,
   [Empresa] = COALESCE(o.sNombre, 'No registra')

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
LEFT JOIN SimOrganizacion o ON ti.nIdOrganizacion = o.nIdOrganizacion
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND o.nIdOrganizacion IS NULL
   AND ccm.nIdCalSolicitada IN (

      SELECT cm.nIdCalidad
      FROM SimCalidadMigratoria cm
      WHERE 
         cm.bActivo = 1
         AND cm.sDescripcion LIKE '%trab%'

   )

EXEC sp_help SimCarnetExtranjeria

-- 1.2: Visualización de datos:
SELECT
   t.sNumeroTramite,
   [sTipoTramite] = tt.sSigla,
   [sCalidad] = cm.sDescripcion,
   ti.sEstadoActual,
   [dFechaTramite] = t.dFechaHora,
   o.nIdOrganizacion,
   [sOrganización] = o.sNombre
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
LEFT JOIN SimOrganizacion o ON ti.nIdOrganizacion = o.nIdOrganizacion
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND ccm.nIdCalSolicitada IN (

      SELECT cm.nIdCalidad
      FROM SimCalidadMigratoria cm
      WHERE 
         cm.bActivo = 1
         AND cm.sDescripcion LIKE '%trab%'
   )


-- Test ...
SELECT * 
FROM SimOrganizacion o
-- ======================================================================================================================================================================== */


-- 2. Extranjeros con CE, registran direcciones incongruentes ...
-- ======================================================================================================================================================================== */

-- 2.1
-- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
DROP TABLE IF EXISTS tmp_ce
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   ce.sNumeroCarnet,
   [Calidad Migratoria] = 'Residente',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  )
   INTO tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND ti.sEstadoActual IN ('A')
   AND t.nIdTipoTramite IN (58, 62) -- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 
                                    --     58 ↔ CAMBIO DE CALIDAD MIGRATORIA

-- 2.2
-- CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS tmp_ptp
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   ce.sNumeroCarnet,
   [Calidad Migratoria] = 'CPP/PTP',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  )
   INTO tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND ti.sEstadoActual IN ('A')
   AND t.nIdTipoTramite IN (92, 113, 126) -- CPP: 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 
                                          --      113 ↔ REGULARIZACION DE EXTRANJEROS; 
                                          --      126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109

-- 2.3: Final ...
SELECT
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [nÜmero Carnet] = e3.sNumeroCarnet,
   [Calidad Migratoria] = cm.sDescripcion,
   [sDireccion] = se.sDomicilio 
FROM (

   SELECT e2.*
   FROM (

      SELECT
         e.*,
         [nReciente] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
      FROM (
         SELECT * FROM tmp_ce
         UNION ALL
         SELECT * FROM tmp_ptp
      ) e

   ) e2
   WHERE e2.nReciente = 1

) e3
JOIN SimPersona p ON e3.uIdPersona = p.uIdPersona
JOIN SimExtranjero se ON p.uIdPersona = se.uIdPersona
JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad

-- ======================================================================================================================================================================== */

-- 3. Extranjeros con Calidad Migratoria `TURISTA` sin nacionalidad en Control Migratorio ...
-- ======================================================================================================================================================================== */

SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = mm.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Calidad Migratoria] = cm.sDescripcion,
   [Id Dependencia] = d.sSigla,
   [Dependencia] = d.sNombre

FROM SimMovMigra mm 
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
JOIN SimDependencia d On mm.sIdDependencia = d.sIdDependencia
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.dFechaControl >= '2008-01-01 00:00:00.000'
   AND mm.nIdCalidad IN ( -- TURISTA
                           SELECT cm.nIdCalidad 
                           FROM SimCalidadMigratoria cm 
                           WHERE 
                              cm.bActivo = 1
                              AND cm.sDescripcion LIKE '%turi%'
   )
   -- AND (p.sIdPaisNacimiento NOT IN ('NNN', 'PER') AND p.sIdPaisNacimiento IS NOT NULL)
   AND (mm.sIdPaisNacionalidad = 'NNN' OR mm.sIdPaisNacionalidad IS NULL)


-- ======================================================================================================================================================================== */


-- 4. Ciudadanos con nacionalidad `PERUANA` realizaron control migratorio con mas de 1 documento (DNI) ...
-- ======================================================================================================================================================================== */

SELECT p2.* 
FROM (

   SELECT

      [Id Persona] = p.uIdPersona,
      [Nombres] = p.sNombre,
      [Apellido 1] = p.sPaterno,
      [Apellido 2] = p.sMaterno,
      [Sexo] = p.sSexo,
      [Fecha de Nacimiento] = p.dFechaNacimiento,
      [Nacionalidad ] = p.sIdPaisNacionalidad,

      -- Aux
      dp.sIdDocumento,
      dp.sNumero,
      [nCant(Id, DNI, NumDoc)] = COUNT(1) OVER (
                                       PARTITION BY 
                                          dp.uIdPersona,
                                          dp.sIdDocumento,
                                          dp.sNumero
                                    ),
      [nCant(Id, DNI)] = COUNT(1) OVER (
                                       PARTITION BY 
                                          dp.uIdPersona,
                                          dp.sIdDocumento
                                    )
   FROM SImDocPersona dp
   JOIN SimPersona p ON dp.uIdPersona = p.uIdPersona
   WHERE 
      (dp.bActivo = 1 AND p.bActivo = 1)
      AND p.sIdPaisNacionalidad = 'PER'
      AND dp.sIdDocumento = 'DNI'
      AND EXISTS (
                     SELECT TOP 1 1 
                     FROM SimMovMigra mm
                     WHERE
                        mm.bAnulado = 0
                        AND mm.bTemporal = 0
                        AND (mm.uIdPersona = dp.uIdPersona AND mm.sIdDocumento = dp.sIdDocumento AND mm.sNumeroDoc = dp.sNumero)
      )

) p2
WHERE
   p2.[nCant(Id, DNI, NumDoc)] = 1 AND p2.[nCant(Id, DNI)] >= 2

-- ======================================================================================================================================================================== */


-- 5. Control migratorio de ciudadanos con Calidad Migratoria `PERUANO` y tipo de documento de viaje `CIP`.
-- ======================================================================================================================================================================== */

-- 21 ↔ PERUANO
-- CIP ↔ DOC. IDENTIFICACION PERSONAL
SELECT 

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

      -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo] = mm.sTipo,
   [Calidad Migratoria] = cm.sDescripcion,
   [Documento] = mm.sIdDocumento

FROM SimMovMigra mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sTipo = 'E'
   -- AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND mm.dFechaControl >= '2019-01-01 00:00:00.000'
   AND mm.sIdDocumento = 'CIP'-- CIP ↔ DOC. IDENTIFICACION PERSONAL
   AND mm.sIdPaisNacionalidad = 'PER'
   AND mm.nIdCalidad = 21 -- 21 ↔ PERUANO


-- ======================================================================================================================================================================== */




-- 6. Ingreso de `Menores de 9 años` con Partida de Nacimiento sin Calidad `HUMANITARIA` .