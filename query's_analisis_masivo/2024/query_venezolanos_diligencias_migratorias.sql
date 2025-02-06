USE SIM
GO

-- 1. Crea `tmp`
-- Nombres | Paterno | Materno | Nacionalidad | Documento | NumeroDoc

-- 1.1
-- EXEC sp_help SimPersona
SELECT
   TOP 0
   pe.sNombre,
   pe.sPaterno,
   pe.sMaterno,
   pe.sIdPaisNacionalidad,
   pe.sIdDocIdentidad,
   pe.sNumDocIdentidad
   INTO BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
FROM SimPersona pe

ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   ADD uIdPersona UNIQUEIDENTIFIER NULL

-- 1.2 Bulk ...
SELECT COUNT(1) FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
-- INSERT INTO BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra VALUES()


-- 2. Inserta el `uIdPersona` en `RimVenDiligenciasMigra`.
CREATE SYNONYM RimVenDiligenciasMigra 
   FOR BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra

-- 2.1
UPDATE RimVenDiligenciasMigra
   SET uIdPersona = (
                        SELECT TOP 1 pe.uIdPersona
                        FROM SimPersona pe 
                        WHERE 
                           pe.sNombre = v.sNombre
                           AND pe.sPaterno = v.sPaterno
                           AND pe.sMaterno = v.sMaterno
                           AND pe.sIdPaisNacionalidad = v.sIdPaisNacionalidad
                           AND EXISTS ( -- Registre DOC
                                          SELECT TOP 1 1
                                          FROM SimDocPersona dp
                                          WHERE 
                                             dp.uIdPersona = pe.uIdPersona
                                             AND dp.sIdDocumento = v.sIdDocIdentidad
                                             AND dp.sNumero LIKE CONCAT('%', v.sNumDocIdentidad)
                                       )
                           AND EXISTS ( -- Registre control
                                          SELECT TOP 1 1
                                          FROM SimMovMigra mm
                                          WHERE 
                                             mm.bAnulado = 0
                                             AND mm.bTemporal = 0
                                             AND mm.uIdPersona = pe.uIdPersona
                                       )
                        ORDER BY pe.dFechaHoraAud DESC
   )
FROM RimVenDiligenciasMigra v

SELECT * FROM RimVenDiligenciasMigra v WHERE v.uIdPersona IS NULL

-- 3. Actualiza ultimo movimiento migratorio en `RimVenDiligenciasMigra`.
-- 3.1
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   -- ADD sUltimoMovimiento CHAR(1) NULL
   -- ADD dFechaUltimoMovimiento DATETIME2 NULL
   ADD sIdPaisMovUltimoMovimiento CHAR(3) NULL

-- 3.2

-- 3.2.1
DROP TABLE IF EXISTS #tmp_ven_ult_mm
SELECT f.* INTO #tmp_ven_ult_mm
FROM (
   SELECT 
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM RimVenDiligenciasMigra v
   JOIN SimMovMigra mm ON v.uIdPersona = mm.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
) f
WHERE f.[#] = 1

-- 3.2.2
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sUltimoMovimiento = mm.sTipo,
       dFechaUltimoMovimiento = mm.dFechaControl,
       sIdPaisMovUltimoMovimiento = mm.sIdPaisMov
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
JOIN #tmp_ven_ult_mm um ON v.uIdPersona = um.uIdPersona
JOIN SimMovMigra mm ON um.sIdMovMigratorio = mm.sIdMovMigratorio

-- 4. Actualiza ultima calidad migratoria en `RimVenDiligenciasMigra`.
-- 4.1
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   ADD sCalidadMigratoriaActual VARCHAR(100) NULL

-- 4.2 Ultima calidad migratoria
DROP TABLE IF EXISTS #tmp_ven_ult_cm
SELECT f.* INTO #tmp_ven_ult_cm
FROM (

   SELECT
      t.uIdPersona,
      [sCalidadMigratoria] = cm.sDescripcion,
      [#] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY t.dFechaHora DESC)
   FROM SimTramite t
   JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
   JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
   WHERE
      t.bCancelado = 0
      -- AND t.bCulminado = 1
      AND ti.sEstadoActual = 'A'
      AND t.nIdTipoTramite IN (
                  58, -- 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
                  92, -- 92 ↔ Permiso Temporal de Permanencia - Venezolanos
                  113, -- 113 ↔ REGULARIZACION DE EXTRANJEROS
                  126 -- 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
            )
                                                 
      AND EXISTS ( -- VEN
                     SELECT 1
                     FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
                     WHERE v.uIdPersona = t.uIdPersona
      )

) f
WHERE f.[#] = 1

-- 4.3
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sCalidadMigratoriaActual = COALESCE(uc.sCalidadMigratoria, cm.sDescripcion)
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
JOIN SimPersona pe ON v.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
LEFT JOIN #tmp_ven_ult_cm uc ON v.uIdPersona = uc.uIdPersona


-- 5 Datos de familiares

-- 5.1 Crea campo `sDatosFamiliares`
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   ADD sDatosFamiliares VARCHAR(4000) NULL

-- 5.2 ...
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sDatosFamiliares = COALESCE(
                                    (
                                       SELECT 
                                          [Parentesco] = stp.sDescripcion,
                                          [Nombre] = sf.sNombre,
                                          [Paterno] = sf.sPaterno,
                                          [Materno] = sf.sMaterno,
                                          [Sexo] = sf.sSexo,
                                          [FechaNacimiento] = sf.dFechaNacimiento,
                                          [PaisNacionalidad] = sf.sIdPaisNacionalidad
                                       FROM SimFamiliarExt sfe
                                       JOIN SimFamiliar sf ON sfe.nIdFamiliar = sf.nIdFamiliar
                                       LEFT JOIN SimTipoParentesco stp ON sfe.nIdParentesco = stp.nIdParentesco
                                       WHERE
                                          sfe.uIdPersona = v.uIdPersona
                                       FOR XML PATH('')

                                    ), (
                                       SELECT 
                                          [Parentesco] = df.sDescripcion,
                                          [Nombre] = df.sNombres,
                                          [Paterno] = df.sPaterno,
                                          [Materno] = df.sMaterno,
                                          [Sexo] = df.sSexo,
                                          [FechaNacimiento] = df.dFechaNacimiento,
                                          [PaisDocumento] = df.sIdPaisDocumento 
                                       FROM (

                                          SELECT 
                                             snf.*,
                                             stp.sDescripcion,
                                             [nFila_uId] = ROW_NUMBER() OVER (PARTITION BY snf.sNombres, snf.sPaterno, snf.sMaterno 
                                                                              ORDER BY snf.sNombres)
                                          FROM SimSistPersonaDatosAdicionalPDA spda
                                          JOIN SimNucleoFamiliarPDA snf ON spda.nIdCitaVerifica = snf.nIdCitaVerifica
                                                                        AND spda.nIdTipoTramite = snf.nIdTipoTramite
                                          JOIN SimTipoParentesco stp ON snf.sIdParentesco = stp.nIdParentesco
                                          WHERE
                                             snf.bActivo = 1
                                             AND spda.uIdPersona = v.uIdPersona

                                       ) df
                                       WHERE
                                          df.nFila_uId = 1
                                       FOR XML PATH('')
                                    )
                                 )
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v



-- 6. Dirección
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   ADD sDireccionDomiciliaria VARCHAR(500) NULL

-- 6.1
DROP TABLE IF EXISTS #tmp_ven_dir_pda
SELECT f.* INTO #tmp_ven_dir_pda
FROM (
   SELECT 
      sapda.uIdPersona,
      [sDireccionBeneficiario] = CONCAT(u.sNombre, '; ', sdpda.sDireccionBeneficiario),
      sapda.dFechaHoraAud,
      [#] = ROW_NUMBER() OVER (PARTITION BY sapda.uIdPersona ORDER BY sapda.dFechaHoraAud DESC)
   FROM [dbo].[SimSistPersonaDatosAdicionalPDA] sapda
   JOIN [dbo].[SimDireccionPDA] sdpda ON sapda.nIdCitaVerifica = sdpda.nIdCitaVerifica
                                    AND sapda.nIdTipoTramite = sdpda.nIdTipoTramite
   JOIN SimUbigeo u ON sdpda.sIdUbigeoBeneficiario = u.sIdUbigeo
   WHERE
      EXISTS ( -- VEN
               SELECT 1
               FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
               WHERE v.uIdPersona = sapda.uIdPersona
         )
) f
WHERE f.[#] = 1

-- 6.2 Dirección: `SimExtranjero`
DROP TABLE IF EXISTS #tmp_ven_dir_pe
SELECT 
   e.uIdPersona,
   [sDireccionBeneficiario] = CONCAT(u.sNombre, '; ', e.sDomicilio),
   e.dFechaHoraAud,
   [#] = 0
   INTO #tmp_ven_dir_pe
FROM SimExtranjero e
LEFT JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
WHERE
   EXISTS ( -- VEN
            SELECT 1
            FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
            WHERE v.uIdPersona = e.uIdPersona
      )

-- 6.3 Final

-- 6.3.1
SELECT * INTO #tmp_ven_dir_f
FROM (
   SELECT 
      *,
      [#f] = ROW_NUMBER() OVER (PARTITION BY u.uIdPersona ORDER BY u.dFechaHoraAud DESC)
   FROM (
      SELECT * FROM #tmp_ven_dir_pda
      UNION ALL
      SELECT * FROM #tmp_ven_dir_pe
   ) u
) f
WHERE f.[#f] = 1

-- 6.3.2
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sDireccionDomiciliaria = d.sDireccionBeneficiario
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
JOIN #tmp_ven_dir_f d ON v.uIdPersona = d.uIdPersona


-- 7. PTP

-- 7.1 
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   -- ADD sNumeroCarnet VARCHAR(55) NULL
   ADD dFechaCaducidadCarnetPTP DATETIME2 NULL

-- 7.2
DROP TABLE IF EXISTS #tmp_ven_ptp
SELECT f.* INTO #tmp_ven_ptp
FROM (
   SELECT 
      c.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY c.uIdPersona ORDER BY c.dFechaEmision DESC)
   FROM SimCarnetPTP c
   WHERE
      -- c.bEntregado = 1
      EXISTS ( -- VEN
               SELECT 1
               FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
               WHERE v.uIdPersona = c.uIdPersona
         )
) f
WHERE f.[#] = 1

-- 7.3
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sNumeroCarnet = c.sNumeroCarnet,
       dFechaCaducidadCarnetPTP = c.dFechaCaducidad
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
JOIN #tmp_ven_ptp c ON v.uIdPersona = c.uIdPersona


-- 8
ALTER TABLE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   -- ADD sTramiteNacionalidad VARCHAR(255) NULL
   ADD sEstadoTramiteNacionalidad VARCHAR(55) NULL



-- 8.1
DROP TABLE IF EXISTS #tmp_ven_nac
SELECT f.* INTO #tmp_ven_nac
FROM (
   SELECT 
      t.uIdPersona,
      [sTramiteNacionalidad] = tt.sDescripcion,
      [sEstadoTramiteNacionalidad] = (
                                       CASE tn.sEstadoActual
                                          WHEN 'P' THEN 'PENDIENTE'
                                          WHEN 'R' THEN 'ANULADO'
                                          WHEN 'D' THEN 'DENEGADO'
                                          WHEN 'A' THEN 'APROBADO'
                                          WHEN 'E' THEN 'DESISTIDO'
                                          WHEN 'B' THEN 'ABANDONO'
                                          WHEN 'N' THEN 'NO PRESENTADA'
                                       END
                                    ),
      [#] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY t.dFechaHora DESC)
   FROM SimTramite t
   JOIN SimTramiteNac tn ON t.sNumeroTramite = tn.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      AND EXISTS ( -- VEN
                     SELECT 1
                     FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
                     WHERE v.uIdPersona = t.uIdPersona
         )
) f
WHERE f.[#] = 1

-- 8.3
UPDATE BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra
   SET sTramiteNacionalidad = n.sTramiteNacionalidad,
       sEstadoTramiteNacionalidad = n.sEstadoTramiteNacionalidad
FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
JOIN #tmp_ven_nac n ON v.uIdPersona = n.uIdPersona

-- Final
SELECT * FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra