USE SIM
GO


/*»
   → 1. Población extranjera 
-- =============================================================================================================================================================== */

-- 1.1
-- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
DROP TABLE IF EXISTS #tmp_ce
SELECT
   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   [dFechaVencRes] = COALESCE(ce.dFechaVencRes, ce.dFechaCaducidad),
   [sEstadoCE] = (
                     CASE
                        WHEN t.bCulminado = 0 THEN 'En Proceso'
                        ELSE ( -- Culminado
                           CASE
                              WHEN (ce.dFechaVencRes IS NOT NULL) THEN (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaVencRes) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaVencRes) > 0 THEN 'Vigente'
                                 END
                              )
                              ELSE (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                                 END
                              )
                           END
                        )
                     END

                  )
   INTO #tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual IN ('A', 'P')


-- 1.2. CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS #tmp_ptp
SELECT
   
   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   [dFechaVencRes] = COALESCE(ce.dFechaVenc, ce.dFechaCaducidad),
   [sEstadoCE] = (
                     CASE
                        WHEN t.bCulminado = 0 THEN 'En Proceso'
                        ELSE ( -- Culminado
                           CASE
                              WHEN (ce.dFechaVenc IS NOT NULL) THEN (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaVenc) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaVenc) > 0 THEN 'Vigente'
                                 END
                              )
                              ELSE (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                                 END
                              )
                           END
                        )
                     END
                  )
   INTO #tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual IN ('A', 'P')


-- 1.2. CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS #tmp_visa
SELECT
   
   t.uIdPersona,
   t.sNumeroTramite,
   [sNumeroCarnet] = v.sOficinaConsular,
   [dFechaEmision] = v.dFechaInicioVigencia,
   [dFechaVencRes] = COALESCE(v.dFechaVencimiento, v.dFechaFinVigencia),
   [sEstadoCE] = (
                     CASE
                        WHEN t.bCulminado = 0 THEN 'En Proceso'
                        ELSE ( -- Culminado
                           CASE
                              WHEN (v.dFechaVencimiento IS NOT NULL) THEN (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), v.dFechaVencimiento) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), v.dFechaVencimiento) > 0 THEN 'Vigente'
                                 END
                              )
                              ELSE (
                                 CASE
                                    WHEN DATEDIFF(dd, GETDATE(), v.dFechaFinVigencia) <= 0 THEN 'Vencida'
                                    WHEN DATEDIFF(dd, GETDATE(), v.dFechaFinVigencia) > 0 THEN 'Vigente'
                                 END
                              )
                           END
                        )
                     END
                  )
   INTO #tmp_visa
FROM SimVisa v
JOIN SimTramite t ON v.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual IN ('A')

-- 2.3: Final ...

-- 2.3.1 Resumen:
DROP TABLE IF EXISTS #tmp_residentes
SELECT 

   e2.*,
   [sCalidadMigratoria] = cm.sDescripcion

   INTO #tmp_residentes

FROM (

   SELECT 
      e.*,
      [nReciente] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
   FROM (
      SELECT * FROM #tmp_ce
      UNION ALL
      SELECT * FROM #tmp_ptp
      UNION ALL
      SELECT * FROM #tmp_visa
   ) e

) e2
JOIN SimPersona pe ON e2.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
WHERE
   NOT EXISTS ( -- No registra cancelación de calidad, posterio a la emisión CE.
      SELECT 1 FROM SimTramite t
      JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
      WHERE
         t.bCancelado = 0
         AND t.uIdPersona = pe.uIdPersona
         AND t.nIdTipoTramite IN (45, 66, 116) -- 45 ↔ CANC. PERMANENCIA/RESIDENCIA X OFICIO; 66  ↔ CANCE.RESIDENCIA Y SALIDA DEF.; 116 ↔ CANCELACIÓN CALIDAD MIGRATORIA Y PERMISO TEMPORAL
         AND ti.sEstadoActual = 'A'
         AND t.dFechaHora > e2.dFechaEmision
   )
   -- e2.nReciente = 1 -- Resiente
   AND e2.sEstadoCE IN ('En Proceso', 'Vigente') -- Residencia vigente
   -- e2.sEstadoCE IN ('Vigente') -- Residencia vigente
   -- AND pe.sIdPaisNacionalidad = 'CUB'
   AND pe.sIdPaisNacionalidad IN ('TWN', 'HNK')



-- 2.3.2 Por año:
SELECT pv.*
FROM (

   SELECT
      e.uIdPersona,
      [sEstadoCalidad] = e.sEstadoCE
   FROM #tmp_residentes e

) f
PIVOT (
   COUNT(f.uIdPersona) FOR f.[sEstadoCalidad] IN ([En Proceso], [Vigente], [Vencida])
) pv

-- 2.3.2 Por año:
SELECT * 
FROM (
   SELECT 
      -- e2.sEstadoCE,
      [nAño] = DATEPART(YYYY, e2.dFechaEmision),
      e2.uIdPersona
   FROM (
      SELECT
         e.*,
         [nReciente] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
      FROM (
         SELECT * FROM #tmp_ce
         UNION ALL
         SELECT * FROM #tmp_ptp
      ) e
      WHERE e.sEstadoCE IN ('En Proceso', 'Vigente')
   ) e2
   WHERE
      e2.nReciente = 1
) e3 
PIVOT (
   COUNT(e3.uIdPersona) FOR e3.[nAño] IN ([2020], [2021], [2022], [2023], [2024])
) pv


-- 3.4: Final
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Fecha Trámite] = CAST(t.dFechaHora AS DATE),
   [Número Trámite] = t.sNumeroTramite,
   [Número Carnet] = r.sNumeroCarnet,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (
                        CASE ti.sEstadoActual 
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'B' THEN 'ABANDONADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'N' THEN 'NO PRESENTADO'
                           WHEN 'R' THEN 'ANULADO'
                        END
   ),
   [Calidad Migratoria] = r.sCalidadMigratoria,
   [Profesión/Ocupación] = f.sDescripcion,
   [Vencimiento Residencia] = r.dFechaVencRes,
   [Estado Residencia] = r.sEstadoCE

FROM #tmp_residentes r
JOIN SimTramite t ON r.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON r.uIdPersona = pe.uIdPersona
LEFT JOIN SimProfesion f ON pe.sIdProfesion = f.sIdProfesion
WHERE 
   r.dFechaEmision BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'

-- WHERE
   -- t.bCancelado = 0
   -- AND t.nIdTipoTramite = 58 -- CAMBIO DE CALIDAD MIGRATORIA
   -- r.sEstadoCE = 'Vigente'


/*==============================================================================================================================================================*/

-- 1
SELECT TOP 10 * 
FROM SimMovMigra mm
ORDER BY mm.dFechaControl DESC

-- 2
SELECT * 
FROM SimProfesion f
WHERE 
   f.sDescripcion LIKE '%med%'
   OR f.sDescripcion LIKE '%ciru%'


