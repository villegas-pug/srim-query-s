USE SIM
GO

/*»
   → 1. Población extranjera residentes
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

SELECT * FROM SimCarnetExtranjeria ce
WHERE ce.sNumeroCarnet = '003154105'


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


-- 1.3. Solicitud Calidad Migratoria
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
SELECT f.* INTO #tmp_residentes
FROM (

   SELECT 

      e2.*,
      [sCalidadMigratoria] = cm.sDescripcion

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
      /* NOT EXISTS ( -- No registra cancelación de calidad, posterio a la emisión CE.
         SELECT 1 FROM SimTramite t
         JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
         WHERE
            t.bCancelado = 0
            AND t.uIdPersona = pe.uIdPersona
            AND t.nIdTipoTramite IN (45, 66, 116) -- 45 ↔ CANC. PERMANENCIA/RESIDENCIA X OFICIO; 66  ↔ CANCE.RESIDENCIA Y SALIDA DEF.; 116 ↔ CANCELACIÓN CALIDAD MIGRATORIA Y PERMISO TEMPORAL
            AND ti.sEstadoActual = 'A'
            AND t.dFechaHora > e2.dFechaEmision
      ) */
      e2.nReciente = 1 -- Resiente
      -- AND e2.sEstadoCE IN ('En Proceso', 'Vigente') -- Residencia vigente
      -- AND e2.sEstadoCE IN ('Vigente') -- Residencia vigente
      -- AND pe.sIdPaisNacionalidad = 'CUB'
      -- AND pe.sIdPaisNacionalidad IN ('TWN', 'HNK')
      AND pe.sIdPaisNacionalidad IN ('VEN', 'CUB', 'IRN', 'ECU', 'COL', 'BRA', 'CHL')
      -- AND e2.dFechaEmision >= '2020-01-01 00:00:00.000' -- Ultimos 5 años
) f
WHERE 
   f.sEstadoCE = 'Vencida'




-- 2.3.2 Turistas que superaron su permanecia.

-- 2.3.2.1 Turistas que superaron su permanecia.
DROP TABLE IF EXISTS #tmp_tur_exceden_permanencia
SELECT 
   mm2.*
   INTO #tmp_tur_exceden_permanencia
FROM (

   SELECT
      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2020-01-01 00:00:00.000'
      AND pe.nIdCalidad IN (41, 227) -- 41 | TURISTA: 227 | TURISTA
      -- AND pe.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero
      AND pe.sIdPaisNacionalidad IN ('VEN', 'CUB', 'IRN', 'ECU', 'COL', 'BRA', 'CHL')

) mm2
WHERE 
   mm2.[#] = 1 -- Ultimo movimiento
   AND mm2.sTipo = 'E' -- Dentro
   AND DATEDIFF(DD, mm2.dFechaControl, GETDATE()) >= mm2.nPermanencia -- Permanencia otorgada vencida

-- 2.3.2.2 Final
DROP TABLE IF EXISTS #tmp_irregulares
SELECT 
   e.*
   INTO #tmp_irregulares
FROM #tmp_tur_exceden_permanencia e
WHERE
   NOT EXISTS (
                  SELECT 1 FROM #tmp_residentes r
                  WHERE 
                     r.uIdPersona = e.uIdPersona
                     AND r.sEstadoCE IN ('En Proceso', 'Vigente')
   )


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

-- 2.3.3 Por año:
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


-- 2.3.4: Por profesión:
SELECT

   [Profesión/Ocupación] = f.sDescripcion,
   [Calidad Migratoria] = r.sCalidadMigratoria,
   COUNT(1)

FROM #tmp_residentes r
JOIN SimPersona pe ON r.uIdPersona = pe.uIdPersona
LEFT JOIN SimProfesion f ON pe.sIdProfesion = f.sIdProfesion
GROUP BY
   f.sDescripcion,
   r.sCalidadMigratoria


-- 2.3.5: Por datos adicionales
DROP TABLE IF EXISTS BD_SIRIM.dbo.tmp_irregulares
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
   
   INTO BD_SIRIM.dbo.tmp_irregulares

FROM #tmp_residentes r
JOIN SimTramite t ON r.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON r.uIdPersona = pe.uIdPersona
LEFT JOIN SimProfesion f ON pe.sIdProfesion = f.sIdProfesion
WHERE 
   -- r.dFechaEmision BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998' */
   -- t.bCancelado = 0
   -- AND t.nIdTipoTramite = 58 -- CAMBIO DE CALIDAD MIGRATORIA
   r.sEstadoCE = 'Vencida' -- Irregulares
   AND pe.sIdPaisNacionalidad IN ('VEN', 'CUB', 'IRN', 'ECU', 'COL', 'BRA', 'CHL')
   AND EXISTS ( -- Dentro
               SELECT 
                  1
               FROM (

                  SELECT
                     mm.*,
                     [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
                  FROM SimMovMigra mm
                  WHERE
                     mm.bAnulado = 0
                     AND mm.bTemporal = 0
                     AND mm.uIdPersona = r.uIdPersona

               ) mm2
               WHERE 
                  mm2.[#] = 1 -- Ultimo movimiento
                  AND mm2.sTipo = 'E' -- Dentro

   )

-- 2.3.6: Relación nominal de irregulares.
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Fecha Ingreso] = CAST(i.dFechaControl AS DATE),
   [Procedencia] = i.sIdPaisMov,
   [Medio Transporte] = i.sIdViaTransporte,
   [Permancencia Otorgada(Días)] = i.nPermanencia,
   [Calidad Migratoria] = cm.sDescripcion

FROM #tmp_irregulares i
JOIN SimPersona pe ON pe.uIdPersona = i.uIdPersona
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad





SELECT 
   /* -- [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Fecha Ingreso] = '',
   [Procedencia] = '',
   [Medio Transporte] = '',
   [Permancencia Otorgada(Días)] = '',
   [Calidad Migratoria] = '' */
   COUNT(1)
FROM #tmp_residentes r
JOIN SimPersona pe ON pe.uIdPersona = r.uIdPersona
WHERE 
   r.sEstadoCE IN ('Vencida')
   AND pe.sIdPaisNacionalidad IN ('VEN', 'CUB', 'IRN', 'ECU', 'COL', 'BRA', 'CHL')
   AND EXISTS ( -- Dentro
               SELECT 
                  1
               FROM (

                  SELECT
                     mm.*,
                     [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
                  FROM SimMovMigra mm
                  WHERE
                     mm.bAnulado = 0
                     AND mm.bTemporal = 0
                     AND mm.uIdPersona = r.uIdPersona

               ) mm2
               WHERE 
                  mm2.[#] = 1 -- Ultimo movimiento
                  AND mm2.sTipo = 'E' -- Dentro

   )


-- ==============================================================================================================================================================*/
