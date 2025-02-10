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

-- 3. Se define como regla, que extranjeros con calidad migratoria `TURISTA`, deben registrar una nacionalidad valida.
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
   AND mm.nIdCalidad IN ( -- TURISTA
                           SELECT cm.nIdCalidad 
                           FROM SimCalidadMigratoria cm 
                           WHERE 
                              cm.bActivo = 1
                              AND cm.sDescripcion LIKE '%turi%'
   )
   AND (mm.sIdPaisNacionalidad = 'NNN' OR mm.sIdPaisNacionalidad IS NULL)


-- ======================================================================================================================================================================== */


-- 4. Se define como regla, que un documento de viaje Documento Nacional de Indentidad(DNI) de peruano, debe ser personal.
-- ======================================================================================================================================================================== */

-- 4.1 `tmp` contar más de 1 dni y agrupa por uId y dni.
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_1
SELECT p2.* INTO #tmp_mm_dni_vinculado_1
FROM (
   SELECT
      [Id Persona] = pe.uIdPersona,
      [Nombres] = pe.sNombre,
      [Apellido 1] = pe.sPaterno,
      [Apellido 2] = pe.sMaterno,
      [Sexo] = pe.sSexo,
      [Fecha de Nacimiento] = pe.dFechaNacimiento,
      [Nacionalidad] = pe.sIdPaisNacionalidad,
      -- Aux
      mm.sIdMovMigratorio,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.nIdOperadorDigita,

      -- [nCant(NumDoc)] = COUNT(1) OVER (PARTITION BY mm.sNumeroDoc),
      [#(uId, NumDoc)] = ROW_NUMBER() OVER (
                                             PARTITION BY
                                                   mm.uIdPersona,
                                                   mm.sNumeroDoc
                                             ORDER BY mm.dFechaControl DESC
                                          )
   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND pe.sIdPaisNacionalidad = 'PER'
      AND mm.sIdDocumento = 'DNI'
      AND ISNUMERIC(mm.sNumeroDoc) = 1
      AND LEN(mm.sNumeroDoc) = 8

) p2
WHERE
   p2.[#(uId, NumDoc)] = 1

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_mm_dni_vinculado_1 ON #tmp_mm_dni_vinculado_1(sNumeroDoc)

-- 4.2 `tmp` Conteo por dni.
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_2
SELECT * INTO #tmp_mm_dni_vinculado_2
FROM (
   SELECT 
      v.*,
      [nCant(NumDoc)(2)] = COUNT(1) OVER (PARTITION BY v.sNumeroDoc)
   FROM #tmp_mm_dni_vinculado_1 v
) f
WHERE f.[nCant(NumDoc)(2)] >= 2

-- 4.3 Documentos de viaje vinculados recientes únicos 
SELECT f.* INTO #tmp_mm_dni_vinculado_uniq
FROM (
   SELECT
      *,
      [#] = ROW_NUMBER() OVER (PARTITION BY v.sNumeroDoc ORDER BY v.sIdMovMigratorio DESC)
   FROM #tmp_mm_dni_vinculado_2 v
) f
WHERE f.[#] = 1

-- 4.4 Final
SELECT 
   vu.sIdMovMigratorio,
   [jDatosDuplicados] = (
      SELECT 
         [Id Mov Migratorio] = v.sIdMovMigratorio,
         v.[Id Persona],
         v.[Nombres],
         v.[Apellido 1],
         v.[Apellido 2],
         v.[Sexo],
         [Fecha Nacimiento] = CAST(v.[Fecha de Nacimiento] AS DATE),
         v.[Nacionalidad],
         [Documento] = v.sIdDocumento,
         [Numero Doc] = v.sNumeroDoc,
         [Login Operador Digita] = COALESCE(u.sLogin, '-'),
         [Operador Digita] = COALESCE(u.sNombre, '-')
      FROM #tmp_mm_dni_vinculado_2 v
      LEFT JOIN SIM.dbo.SimUsuario u ON v.nIdOperadorDigita = u.nIdOperador
      WHERE
         v.[Id Persona] != vu.[Id Persona]
         AND v.sNumeroDoc = vu.sNumeroDoc
      FOR JSON PATH, ROOT('SimMovMigra')
   )
FROM #tmp_mm_dni_vinculado_uniq vu


-- ======================================================================================================================================================================== */

-- 5. Se define como regla, que el control migratorio de ciudadanos con calidad migratoria `PERUANO`, el tipo de documento de viaje no deberia ser `CIP`.
-- ======================================================================================================================================================================== */

-- 21 ↔ PERUANO
-- CIP ↔ DOC. IDENTIFICACION PERSONAL
SELECT 

   /* [Id Persona] = p.uIdPersona,
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
   [Documento] = mm.sIdDocumento */
   mm.sIdMovMigratorio

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona p ON mm.uIdPersona = p.uIdPersona
-- JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento = 'CIP'-- CIP ↔ DOC. IDENTIFICACION PERSONAL
   AND p.sIdPaisNacionalidad = 'PER'
   AND mm.nIdCalidad = 21 -- 21 ↔ PERUANO


-- ======================================================================================================================================================================== */




-- 6. Ingreso de `Menores de 9 años` con Partida de Nacimiento sin Calidad `HUMANITARIA` .