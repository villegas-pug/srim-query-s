USE SIM
GO

/*==============================================================================================================================================================*/
-- 1. CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
DROP TABLE IF EXISTS #tmp_ce
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   t.sNumeroTramite,
   [sTramite] = 'CE/CCM',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  ),
   [bBiometría] = (
                     IIF(
                           EXISTS (
                              SELECT 1
                              FROM SimImagenExtranjero ie
                              WHERE
                                 ce.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                 AND ie.uIdPersona = ce.uIdPersona
                                 AND ie.sTipo IN ('F', 'H') -- Foto o huellas
                                 
                           ),
                           1,
                           0
                     )
   )
   INTO #tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND ti.sEstadoActual IN ('A', 'P')
   AND t.nIdTipoTramite IN (58, 62) -- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 
                                    --     58 ↔ CAMBIO DE CALIDAD MIGRATORIA


-- 2. CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS #tmp_ptp
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   t.sNumeroTramite,
   [sTramite] = 'CPP/PTP',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  ),
   [bBiometría] = (
                     IIF(
                           EXISTS (
                              SELECT 1
                              FROM SimImagenExtranjero ie
                              WHERE
                                 ce.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                 AND ie.uIdPersona = ce.uIdPersona
                                 AND ie.sTipo IN ('F', 'H') -- Foto o huellas
                                 
                           ),
                           1,
                           0
                     )
   )
   INTO #tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND ti.sEstadoActual IN ('A', 'P')
   AND t.nIdTipoTramite IN (92, 113, 126) -- CPP: 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 
                                          --      113 ↔ REGULARIZACION DE EXTRANJEROS; 
                                          --      126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109

-- 3: Final ...
SELECT 
   e2.*,
   ex.sDomicilio
FROM (
   SELECT 
      e.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
   FROM (
      SELECT * FROM #tmp_ce
      UNION ALL
      SELECT * FROM #tmp_ptp
   ) e
) e2
JOIN SimExtranjero ex ON e2.uIdPersona = ex.uIdPersona
WHERE
   e2.[#] = 1

/*==============================================================================================================================================================*/