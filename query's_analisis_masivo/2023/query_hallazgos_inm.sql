USE SIM
GO

--> 1. Calidad solicitada `TRABAJADOR`, no registra Empresa ...
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
-- ==================================================================================================================================================================


--> 2. Se registran Calidad anterior y solicitada iguales .
-- ==================================================================================================================================================================

-- Identificar inconsitencia.
DROP TABLE IF EXISTS #tmp_Calant_igual_calsol
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
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalAnterior,
   [sCalidadAnterion] = cma.sDescripcion,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion
   INTO #tmp_Calant_igual_calsol
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   -- 314 ↔ ACUERDOS INTERNACIONALES - MERCOSUR; 332 ↔ MERCOSUR PERMANENTE
   AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))
   AND ccm.nIdCalAnterior = ccm.nIdCalSolicitada
ORDER BY
   t.dFechaHora DESC

-- =============================================================================================================================================


--> 3. Trámites de Cambio de Calidad en estado aprobado, sin fecha de aprobación.
-- ==================================================================================================================================================================

-- EXEC sp_help SimCambioCalMig
SELECT 

   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- AUx
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion,
   ccm.dFechaAprobacion
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (
      58  -- CCM
      -- 113, -- REGULARIZACION DE EXTRANJEROS
      -- 126  -- PERMISO TEMPORAL DE PERMANENCIA - RS109
   )
   AND ccm.dFechaAprobacion IS NULL
   

-- ==================================================================================================================================================================

--> 4. Extranjeros con CE, registran direcciones incongruentes ...
-- ======================================================================================================================================================================== */

-- 4.1
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

-- 4.2
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

-- 4.3: Final ...
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


-- 5. Prefijo de número de trámite no corresponde a prefijo de trámite de dependencia.
-- ======================================================================================================================================================================== */

-- 5.1
SELECT 
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Tramite] = t.sNumeroTramite,
   [Fecha Trámite] = CAST(t.dFechaHora AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Dependencia] = d.sNombre,
   [Prefijo Trámite Dependencia] = d.sPrefijoTramite
   /* [Dependencia Número Trámite (Prefijo)] = (
                                                SELECT d2.sNombre 
                                                FROM SimDependencia d2 
                                                WHERE 
                                                   d2.bActivo = 1
                                                   AND d2.nIdTipoDependencia = 2 -- 2 | JEFATURA DE MIGRACIONES
                                                   AND d2.sPrefijoTramite = LEFT(LTRIM(t.sNumeroTramite), 2)
   ) */
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   -- AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ISNUMERIC(LEFT(LTRIM(t.sNumeroTramite), 2)) = 0 -- Prefijo únicamente letras
   AND (

      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND LEFT(LTRIM(t.sNumeroTramite), 2)  NOT IN (d.sPrefijoTramite, 'SW')

   )

-- ======================================================================================================================================================================== */

--> 6. Trámites de CCM, CPP y PTP con estato de trámite `PENDIENTE` en etapa que actualiza el estado a `APROBADO` con estado `FINALIZADO` ...
-- ======================================================================================================================================================================== */

-- 6.1
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
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'P'
   -- AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP; 57 ↔ PRORROGA DE RESIDENCIA
   AND t.nIdTipoTramite IN (58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   -- AND t.nIdTipoTramite IN (57)-- 57 ↔ PRORROGA DE RESIDENCIA
   AND EXISTS ( -- Ultimas etapas
      
                  SELECT 1 FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite 
                     AND et.bActivo = 1
                     AND et.sEstado = 'F'
                     AND et.nIdEtapa IN (17, 63, 80) -- 58, 113, 126
                     -- AND et.nIdEtapa IN (24) -- 57
              
   )
   AND NOT EXISTS ( -- Reconsideraciones o apelaciones

         SELECT 
            1
         FROM SimEtapaTramiteInm eti
         WHERE
            eti.sNumeroTramite = t.sNumeroTramite 
            AND eti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
            AND eti.sEstado = 'I'
            AND eti.bActivo = 1
            
   )

-- ======================================================================================================================================================================== */


--> 7. Trámites de PRR, CCM, CPP y PTP con estado de trámite `APROBADO`, sin registro de etapa que actualiza el estado a `APROBADO` ...
-- ======================================================================================================================================================================== */

-- 7.1
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
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   -- [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND YEAR(t.dFechaHora) >= (
                                 SELECT et.nAño
                                 FROM (
                                    VALUES
                                       (2021, 57), -- >=2021  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                       (2022, 58), -- >=2022 = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                       (2021, 113), -- >=2021 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                       (2023, 126) -- >=2023 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 ) et([nAño], [nIdTipoTramite])
                                 WHERE
                                    et.nIdTipoTramite = t.nIdTipoTramite
   )
   AND NOT EXISTS ( -- Etapas que aprueban el trámite ...
      
                  SELECT 1 FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite 
                     AND et.bActivo = 1
                     -- AND et.sEstado = 'F'
                     AND (
                        et.nIdEtapa = (
                                             SELECT et.nIdEtapa
                                             FROM (
                                                VALUES
                                                   (57, 22), -- 57  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                                   (58, 17), -- 58  = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                                   (113, 63), -- 113 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                                   (126, 80) -- 126 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                             ) et([nIdTipoTramite], [nIdEtapa])
                                             WHERE
                                                et.nIdTipoTramite = t.nIdTipoTramite
                        )
                        OR
                        et.nIdEtapa IN (67, 68) -- Reconsideracion y Apelación
                     )
              
   )

-- ======================================================================================================================================================================== */


--> 8. Trámites de PRR, CCM, CPP y PTP con estato de trámite `APROBADO` en etapa que actualiza el estado a `APROBADO` con estado `INICIADO` ...
-- ======================================================================================================================================================================== */

-- 8.1
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
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND YEAR(t.dFechaHora) >= (
                                 SELECT tmp.nAño
                                 FROM (
                                    VALUES
                                       (2021, 57), -- >=2021  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                       (2022, 58), -- >=2022 = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                       (2021, 113), -- >=2021 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                       (2023, 126) -- >=2023 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 ) tmp([nAño], [nIdTipoTramite])
                                 WHERE
                                    tmp.nIdTipoTramite = t.nIdTipoTramite
   )
   AND EXISTS ( -- Etapas que aprueban el trámite ...
                  SELECT 1
                  FROM (
                     SELECT 
                        et.*,
                        [#] = ROW_NUMBER() OVER (ORDER BY et.nIdEtapaTramite DESC)
                     FROM SimEtapaTramiteInm et
                     WHERE
                        et.sNumeroTramite = t.sNumeroTramite 
                  ) et2
                  WHERE 
                     et2.[#] = 1
                     AND et2.bActivo = 1
                     AND et2.sEstado = 'I'
                     AND et2.nIdEtapa = (
                                          SELECT tmp.nIdEtapa
                                          FROM (
                                             VALUES
                                                (57, 22), -- 57  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                                (58, 17), -- 58  = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                                (113, 63), -- 113 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                                (126, 80) -- 126 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                          ) tmp([nIdTipoTramite], [nIdEtapa])
                                          WHERE
                                             tmp.nIdTipoTramite = t.nIdTipoTramite
                                          )
                     )

-- ======================================================================================================================================================================== */


--> 9. Trámites de inmigración con estado de trámite `APROBADOS` en etapa `ASOCIACIÓN BENEFICIARIO`.
-- ======================================================================================================================================================================== */

-- 9.1

SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ti.nIdEtapaActual = 12 -- 12 | ASOCIACION BENEFICIARIO
   AND (
            SELECT COUNT(1)
               FROM (
                  SELECT 
                     et.nIdEtapa,
                     [#] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite)
                  FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite
                     AND et.bActivo = 1

               ) et2
               WHERE
                  et2.[#] = 2
                  AND et2.nIdEtapa IN (11, 12) -- 12 | ASOCIACION BENEFICIARIO; 11 | RECEPCIÓN DINM
            ) = 2
   ORDER BY t.dFechaHora DESC

-- ======================================================================================================================================================================== */

-- 10. Trámites de inmigración con estado de trámite `APROBADO` y registro de etapas con estado `INICIADO`.
-- ======================================================================================================================================================================== */

-- 10.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre,

   --Aux 2
   [Cantidad Etapas (I)] = et.[nCantEtapas(I)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC),
         [nCantEtapas(I)] = COUNT(1) OVER (PARTITION BY eti.sNumeroTramite)
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.sEstado = 'I'
         AND eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1
      AND f.[nCantEtapas(I)] >= 1

) et ON et.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.sEstadoActual = 'A'

-- ======================================================================================================================================================================== */


--> 11. Etapa actual de trámites de inmigración en SIM.dbo.SimTramiteInm, diferente a ultima etapa registrada en SIM.dbo.SimEtapaTramiteInm.
-- ======================================================================================================================================================================== */

-- 11.1
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
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre,

   --Aux
   [Id Etapa (SimTramiteInm)] = ti.nIdEtapaActual,
   [Id Etapa (SimEtapaTramiteInm)] = let.[nIdEtapa(Ult)],
   [Estado Etapa (SimEtapaTramiteInm)] = let.[sEstado(Ult)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]

-- ======================================================================================================================================================================== */

--> 12. Trámites con uIdPersona `00000000-0000-0000-0000-000000000000` en SIM..dbo.SimTramite. 
-- ======================================================================================================================================================================== */
SELECT
   -- 1
   [Nombres] = '',
   [Apellido 1] = '',
   [Apellido 2] = '',
   [Sexo] = '',
   [Fecha Nacimiento] = '',

   -- Aux ...
   st.sNumeroTramite,
   st.uIdPersona,
   [sTipoTramite] = stt.sDescripcion,
   sti.sEstadoActual
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   AND st.dFechaHora >= '2016-01-01 00:00:00.000'
   AND st.uIdPersona = '00000000-0000-0000-0000-000000000000'
-- ======================================================================================================================================================================== */

--> 13. Trámites de inmigración en estado `P`, con ultima etapa ENTREGA DE CARNÉ finalizada y sin reconsideracion ...
-- ======================================================================================================================================================================== */
/*
   ░ Ultima etapa por tipo de trámite ...

      → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
      → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
      → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P. */

SELECT * FROM SimTipoTramite stt
WHERE 
   stt.nIdTipoTramite IN (58, 113, 126)

SELECT
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   st.uIdPersona,
   [dFechaExpendiente] = st.dFechaHora,
   st.sNumeroTramite,
   sti.sEstadoActual,
   [sTipoTramite] = stt.sDescripcion
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   -- AND st.dFechaHora >= '2016-01-01 00:00:00.000'
   AND st.dFechaHora >= '2021-08-01 00:00:00.000' -- A partir de esta fecha la ultima etapa de CCM es `ENTREGA DE CARNET EXTRANJERIA` ...
   AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND st.nIdTipoTramite IN (58, 113, 126)
   AND sti.sEstadoActual = 'P'
   AND EXISTS (

      SELECT
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (
                                 -- → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 -- → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                 -- → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                 SELECT t.nIdEtapaFinal FROM (
                                    VALUES
                                       (58, 17),
                                       (113, 63),
                                       (126, 63),
                                       (126, 80)
                                 ) AS t([nIdTipoTramite], [nIdEtapaFinal])
                                 WHERE
                                    t.nIdTipoTramite = st.nIdTipoTramite
                           )
         AND seti.sEstado = 'F'
         AND seti.bActivo = 1
   )
   AND NOT EXISTS (

      SELECT 
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
         AND seti.sEstado = 'I'
         AND seti.bActivo = 1
         
   )
-- ======================================================================================================================================================================== */