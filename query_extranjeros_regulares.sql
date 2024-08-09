USE SIM
GO


/*»
   → 1. Población extranjera 
-- =============================================================================================================================================================== */

-- 1.1 ...
-- 1.1.1 Extrae población extranjera y si registran biometría ...
-- SELECT * FROM SimDedoBio
-- SELECT TOP 10 * FROM SimImagenExtranjero
DROP TABLE IF EXISTS #tmp_poblacion_extranjera_bio
SELECT
   e.uIdPersona,
	[Estado Calidad] = e.EstadoR3,
	[Detalle Estado calidad] = e.EstadoR2,
   [Situación Migratoria] = CASE 
                                 WHEN CalidadMigratoria = 'Permanente' or CalidadMigratoria = 'Inmigrante' THEN 'Permanente'
                                 WHEN CalidadTipo = 'R' and (CalidadMigratoria != 'Permanente' and CalidadMigratoria != 'Inmigrante') THEN 'Residente'
                                 WHEN CalidadMigratoria = 'Turista' THEN 'Turista'
                                 ELSE 'Otras calidades temporales'
									END,
   [bBiometría] = (
                     CASE 
                        WHEN e.EstadoR3 = 'Regulares' THEN 1
                        ELSE (
                                 IIF(
                                       EXISTS (
                                          SELECT 1
                                          FROM SimImagenExtranjero ie
                                          WHERE
                                             -- ie2.bUltimo = 1
                                             e.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                             AND ie.uIdPersona = e.uIdPersona
                                             AND ie.sTipo IN ('F', 'H') -- Foto o huellas
                                             
                                       ),
                                       1,
                                       0
                                 )

                        )
                     END
   )
   
   INTO #tmp_poblacion_extranjera_bio
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e

SELECT COUNT(1)
FROM #tmp_poblacion_extranjera_bio

-- Aux
ALTER TABLE BD_SIRIM.dbo.RimTotalExtranjerosPeru
   ADD bBiometria BIT NOT NULL DEFAULT(0)
/*
UPDATE BD_SIRIM.dbo.RimTotalExtranjerosPeru
   SET bBiometria = 0

UPDATE BD_SIRIM.dbo.RimTotalExtranjerosPeru
   SET bBiometria = eb.bBiometría
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
JOIN #tmp_poblacion_extranjera_bio eb ON e.uIdPersona = eb.uIdPersona
WHERE
   e.uIdPersona != '00000000-0000-0000-0000-000000000000'*/

-- Validar en base de datos BIO
/*SELECT
   -- TOP 10
   e.uIdPersona
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
WHERE
   e.bBiometria = 0
   AND e.uIdPersona != '00000000-0000-0000-0000-000000000000'*/


-- Test 
SELECT COUNT(1) -- 955,631 ↔ 1
FROM #tmp_poblacion_extranjera_bio e
WHERE e.bBiometría = 0

-- 1.1.2
SELECT
	e.[Estado Calidad],
	e.[Detalle Estado calidad],
   e.[Situación Migratoria],
   e.bBiometría,
	-- [Detalle Estado 2] = e.Detalle_ER2,
   -- e.CalidadMigratoria,
   [nTotal] = COUNT(1)
FROM #tmp_poblacion_extranjera_bio e
/* WHERE
	-- r.Ingreso BETWEEN '2016-01-01 00:00:00.000' AND '2022-12-31 23:59:59.999'
   -- e.EstadoR3 = 'Regulares'
	-- e.Nacionalidad IN ('PARAGUAYA') */
GROUP BY
	e.[Estado Calidad],
   e.[Detalle Estado calidad],
   e.[Situación Migratoria],
   e.bBiometría
   -- e.Detalle_ER2
   -- e.CalidadMigratoria
ORDER BY
   1 DESC, 5 DESC

-- 1.2 Extranjeros ingresaron a `PER` ...
SELECT pv.* FROM (

   SELECT 
      [nMesControl] = DATEPART(MM, m2.dFechaControl),
      m2.uIdPersona
   FROM (

      SELECT
         mm.*,
         [nUltima(e)] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      WHERE 
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sTipo = 'E'
         AND mm.sIdPaisNacionalidad = 'PAR'
         AND mm.dFechaControl BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

   ) m2
   WHERE m2.[nUltima(e)] = 1

) AS m3
PIVOT (
   COUNT(m3.uIdPersona) FOR m3.nMesControl IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 1.3 Nacionalizados con biometría ...

SELECT
   n.bBiometría,
   [nTotal] = COUNT(1)
FROM (
   SELECT
      tn.uIdPersona,
      [bBiometría] = (
                     
                        IIF(
                              EXISTS (
                                 SELECT 1
                                 FROM SimImagenExtranjero ie
                                 WHERE
                                    -- ie2.bUltimo = 1
                                    tn.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                    AND ie.uIdPersona = tn.uIdPersona
                                    AND ie.sTipo IN ('F', 'H') -- Foto o huellas
                                    
                              ),
                              1,
                              0
                        )
      )

   FROM SimTituloNacionalidad tn
   JOIN SimTramite t ON tn.sNumeroTramite = t.sNumeroTramite
   WHERE
      tn.bAnulado = 0
      AND tn.bEntregado = 1
      AND t.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
) n
GROUP BY
   n.bBiometría
/*==============================================================================================================================================================*/


-- 2. v2
/*==============================================================================================================================================================*/

-- 2.1
-- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
DROP TABLE IF EXISTS #tmp_ce
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   -- [Calidad Migratoria] = 'Residente',
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


-- 2.2
-- CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS #tmp_ptp
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   -- [Calidad Migratoria] = 'CPP/PTP',
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
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND ti.sEstadoActual IN ('A', 'P')
   AND t.nIdTipoTramite IN (92, 113, 126) -- CPP: 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 
                                          --      113 ↔ REGULARIZACION DE EXTRANJEROS; 
                                          --      126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109

-- 2.3: Final ...
-- Detalle Estado calidad(Abrev)	Estado calidad(Abrev)	Situación Migratoria	Biometría	 Total 
SELECT 
   e2.[Calidad Migratoria],
   e2.sEstadoCE,
   e2.bBiometría,
   [nTotal] = COUNT(e2.uIdPersona)
FROM (
   SELECT 
      e.*,
      [nReciente] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
   FROM (
      SELECT * FROM #tmp_ce
      UNION ALL
      SELECT * FROM #tmp_ptp
   ) e
) e2
WHERE
   e2.nReciente = 1
GROUP BY
   e2.[Calidad Migratoria],
   e2.sEstadoCE,
   e2.bBiometría

/*==============================================================================================================================================================*/



-- 3: Final ...

SELECT 
   e2.sTipoCalidad,
   e2.sCalidadMigratoria,
   e2.bBiometría,
   [nTotal] = COUNT(1)
FROM (

   SELECT
      p.uIdPersona,
      [sCalidadMigratoria] = cm.sDescripcion,
      [sTipoCalidad] = cm.sTipo,
      [bBiometría] = (
                        IIF(
                              EXISTS (
                                 SELECT 1
                                 FROM SimImagenExtranjero ie
                                 WHERE
                                    p.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                    AND ie.uIdPersona = p.uIdPersona
                                    AND ie.sTipo IN ('F', 'H') -- Foto o huellas
                                    
                              ),
                              1,
                              0
                        )
      )
   FROM SimPersona p
   JOIN SimExtranjero e ON p.uIdPersona = e.uIdPersona
   JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad
   WHERE
      p.bActivo = 1
      AND p.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND p.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero

) e2
GROUP BY
   e2.sTipoCalidad,
   e2.sCalidadMigratoria,
   e2.bBiometría
ORDER BY
   3 DESC


SELECT
   COUNT(1)
FROM SimPersona p
   JOIN SimExtranjero e ON p.uIdPersona = e.uIdPersona
   JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad
WHERE
      p.bActivo = 1
      AND p.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND p.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero


-- 3. Venezolanos Extranjeros regulares
-- 15/07/2019

-- 3.1 SIM.dbo.xTotalExtranjeros
SELECT pv.* 
FROM (

   SELECT
      e.uIdPersona,
      [Año Ingreso] = DATEPART(YYYY, e.dFechaIngreso),
      [Estado Calidad] = UPPER(e.EstadoR3),
      [Calidad Migratoria] = UPPER(e.CalidadMigratoria)
      /* [Situación Migratoria] = CASE 
                                    WHEN CalidadMigratoria = 'Permanente' or CalidadMigratoria = 'Inmigrante' THEN 'Permanente'
                                    WHEN CalidadTipo = 'R' and (CalidadMigratoria != 'Permanente' and CalidadMigratoria != 'Inmigrante') THEN 'Residente'
                                    WHEN CalidadMigratoria = 'Turista' THEN 'Turista'
                                    ELSE 'Otras calidades temporales'
                              END */
      
   FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
   WHERE
      -- e.EstadoR3 = 'Regulares'
      e.Nacionalidad = 'Venezolana'
      AND e.dFechaIngreso >= '2019-07-15 00:00:00.000'

) e2
PIVOT (

   COUNT(e2.uIdPersona) FOR e2.[Año Ingreso] IN ([2019], [2020], [2021], [2022], [2023], [2024])

) pv



-- 3.2 Control Migratorio ...
SELECT pv.* 
FROM (

   SELECT 
      mm2.uIdPersona,
      [Año Control] = DATEPART(YYYY, mm2.dFechaControl),
      [Calidad Migratoria] = mm2.sCalidadMigratoria
   FROM (

      SELECT
         mm.*,
         [sCalidadMigratoria] = cm.sDescripcion,
         [nOrden] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sIdPaisNacionalidad = 'VEN'
         AND mm.sTipo = 'E'
         AND mm.dFechaControl >= '2019-07-15 00:00:00.000'

   ) mm2
   WHERE
      mm2.nOrden = 1

) mm3
PIVOT (
   COUNT(mm3.uIdPersona) FOR mm3.[Año Control] IN ([2019], [2020], [2021], [2022], [2023], [2024])
) pv

-- Test ...
-- 1
SELECT mm2.* 
FROM (

   SELECT
      [Id Persona] = mm.uIdPersona,
      [Fecha Control] = CAST(mm.dFechaControl AS DATE),
      [Dependencia] = d.sNombre,
      [Calidad Migratoria] = cm.sDescripcion,
      mm.sObservaciones,
      [nOrden] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad = 'VEN'
      AND mm.sTipo = 'E'
      AND mm.dFechaControl >= '2019-07-15 00:00:00.000'
      AND mm.sObservaciones LIKE '%visa%'

) mm2
WHERE mm2.nOrden = 1


-- Extranjero menores de edad
/*
   1. Extranjeros por nacionalida irregular e regular menores por grupo etario.
   2. Extranjeros por nacionalida regular menores por calidad.
*/

SELECT
   TOP 10
   r.uIdPersona,
   -- [Año Ingreso] = DATEPART(YYYY, r.dFechaIngreso), */
	[sNacionalidad] = r.Nacionalidad,
   [Grupo Etario] = r.RangoEdad,
   [Genero] = r.Sexo,
   [Calidad Migratoria] = r.CalidadMigratoria,
	-- [Tipo Calidad] = r.CalidadTipo,
	/* [sTipoCalidad] = CASE 
								WHEN r.CalidadMigratoria = 'Permanente' OR r.CalidadMigratoria = 'Inmigrante' THEN 'Permanente'
								WHEN r.CalidadTipo = 'R' AND (r.CalidadMigratoria != 'Permanente' AND r.CalidadMigratoria != 'Inmigrante') THEN 'Residente'
								WHEN r.CalidadMigratoria = 'Turista' THEN 'Turista'
								ELSE 'Otras calidades temporales'
							END, */
	[Situación Migratoria] = r.EstadoR3
   
FROM SIM.dbo.xTotalExtranjerosPeru r
WHERE
   r.Edad < 18 -- Menores
   --AND r.dFechaIngreso >= '2016-01-01 00:00:00.000'
   AND r.CalidadMigratoria = 'PERUANO'
   -- e.EstadoR3 = 'Regulares'
   -- e.Nacionalidad = 'Venezolana'

-- SELECT TOP 10 * FROM SIM.dbo.xTotalExtranjerosPeru e


/* 
   2e4802c9-4376-4558-a5a6-5b386e7707c9
   278f3aad-2dff-40e3-b7b6-43b0cd98fee7
   9b55c5e1-7147-4c82-a19a-d265c8c21787
   9ee867fc-288a-4aaa-9258-61585961f838
 */
SELECT cm.sDescripcion, p.* 
FROM SimPersona p
JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad
WHERE 
   p.uIdPersona = '9ee867fc-288a-4aaa-9258-61585961f838'

SELECT * FROM RimRNProceso
SELECT * FROM RimReglaNegocio
SELECT * FROM RimRNControlCambios
SELECT * FROM RimRNRegistroEjecucionScript

UPDATE RimRNControlCambios
   SET bActivo = 1
WHERE nIdRNControlCambio = 2

DELETE FROM RimRNRegistroEjecucionScript
   WHERE nIdRegistroEjecucion >= 20

