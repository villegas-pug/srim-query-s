USE SIM
Go

SELECT

   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   [Id Persona] = t.uIdPersona,
   [Fecha Expendiente] = t.dFechaHora,
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Estado Trámite Actual] = (

                        CASE t.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END

                     ),
   [Estado Pre-aprobación] = (
                     CASE t.sEstadoPre 
                        WHEN 'A' THEN 'APROBADO'
                        WHEN 'B' THEN 'ABANDONADO'
                        WHEN 'D' THEN 'DENEGADO'
                        WHEN 'E' THEN 'DESISTIDO'
                        WHEN 'N' THEN 'NO PRESENTADO'
                        WHEN 'P' THEN 'PENDIENTE'
                     END
                  )

FROM (

   SELECT
      st.uIdPersona,
      st.nIdTipoTramite,
      st.dFechaHora,
      st.sNumeroTramite,
      sti.sEstadoActual,
      spti.sEstadoPre,
      [nFila_Pre] = ROW_NUMBER() OVER (PARTITION BY spti.sNumeroTramite ORDER BY spti.dFechaPre DESC)
   FROM SimTramite st
   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
   JOIN SimPreTramiteInm spti ON st.sNumeroTramite = spti.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sti.sEstadoActual = 'P'
      AND NOT EXISTS (

         SELECT 
            TOP 1 1
         FROM SimEtapaTramiteInm seti
         WHERE
            seti.sNumeroTramite = st.sNumeroTramite 
            AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
            -- AND seti.sEstado = 'F'
            AND seti.bActivo = 1
            
      )

) t
JOIN SimPersona sper ON t.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON t.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   t.nFila_Pre = 1
   AND t.sEstadoPre != 'A'


-- Test ...
SELECT 
   [sTipoTramite] = tt.sDescripcion,
   [sEtapa] = e.sDescripcion,
   et.*
FROM SimEtapaTramiteInm et
JOIN SImEtapa e ON et.nIdEtapa = e.nIdEtapa
JOIN SimTramite t ON et.sNumeroTramite = t.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   et.bActivo = 1
   AND et.sNumeroTramite = (
                           SELECT
                              TOP 1
                              pre.sNumeroTramite
                           FROM SimPreTramiteInm pre
                           JOIN SimTramite t ON pre.sNumeroTramite = t.sNumeroTramite
                           JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
                           WHERE
                              t.bCancelado = 0
                              AND pre.sEstadoPre = 'A'
                              AND ti.sEstadoActual = 'P'
                              AND t.sIdDependencia IN ('27', '112')
                           ORDER BY NEWID()
   )
ORDER BY
   et.nIdEtapaTramite ASC
   

-- 2. Trámites de inmigración
-- 112 ↔ JEFATURA ZONAL CALLAO
-- 27  ↔ A.I.J.CH.
SELECT
   [Número Tramite] = t.sNumeroTramite,
   [Fecha Trámite] = t.dFechaHora,
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
   [Dependencia] = d.sNombre,
   -- [Calidad Migratoria] = COALESCE(cm.sDescripcion, 'Aún no ha sido ingresado o el trámite no establece una Calidad Migratoria'),
   -- [Etapa Actual] = e.sDescripcion,
   [Etapa Actual] = (
                        SELECT 
                           TOP 1 
                           e.sDescripcion
                        FROM SimEtapaTramiteInm et
                        JOIN SimEtapa e2 ON et.nIdEtapa = e2.nIdEtapa
                        WHERE
                           et.sNumeroTramite = t.sNumeroTramite 
                           AND et.bActivo = 1
                        ORDER BY et.nIdEtapaTramite DESC
                     )
   /* [Estado Etapa Actual(SimEtapaTramiteInm)] = (
                                                      SELECT 
                                                         TOP 1 
                                                         et.sEstado
                                                      FROM SimEtapaTramiteInm et
                                                      WHERE
                                                         et.sNumeroTramite = t.sNumeroTramite 
                                                         AND et.bActivo = 1
                                                      ORDER BY et.nIdEtapaTramite DESC
                                                ) */
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
-- LEFT JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
-- LEFT JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND (
         SELECT
            TOP 1
            et.dFechaHoraFin
         FROM SimEtapaTramiteInm et
         WHERE
            et.sNumeroTramite = t.sNumeroTramite 
            AND et.bActivo = 1
            AND et.sEstado = 'F'
         ORDER BY et.nIdEtapaTramite DESC
   ) BETWEEN '2017-01-01 00:00:00.000' AND '2021-12-31 23:59:59.998'
   -- AND d.sIdDependencia IN ('27', '112')
   -- AND ti.sEstadoActual = 'P'


-- 2.1 Resumen: INM

-- 2.2 Solicitudes:
SELECT pv.* 
FROM (

   SELECT t2.* 
   FROM (

      SELECT
         t.sNumeroTramite,
         [sTipoTramite] = UPPER(tt.sDescripcion),
         [sEstadoTramite] = (
                              CASE ti.sEstadoActual
                                 WHEN 'A' THEN 'APROBADO'
                                 WHEN 'B' THEN 'ABANDONO'
                                 WHEN 'D' THEN 'DENEGADO'
                                 WHEN 'E' THEN 'DESISTIDO'
                                 WHEN 'N' THEN 'NO PRESENTADA'
                                 WHEN 'R' THEN 'ANULADO'
                                 WHEN 'P' THEN 'PENDIENTE'
                                 -- WHEN 'E' THEN ''
                              END
                           ),
         [Dependencia] = d.sNombre,
         [nAñoTramite] = DATEPART(YYYY, t.dFechaHora)
         /* [nAñoEtapaActual] = (
                                 SELECT
                                    TOP 1
                                    DATEPART(YYYY, et.dFechaHoraFin)
                                 FROM SimEtapaTramiteInm et
                                 WHERE
                                    et.sNumeroTramite = t.sNumeroTramite 
                                    AND et.bActivo = 1
                                    AND et.sEstado = 'F'
                                 ORDER BY et.nIdEtapaTramite DESC
                              ) */
         /* [nMesEtapaActual] = (
                                 SELECT
                                    TOP 1
                                    DATEPART(MM, et.dFechaHoraFin)
                                 FROM SimEtapaTramiteInm et
                                 WHERE
                                    et.sNumeroTramite = t.sNumeroTramite 
                                    AND et.bActivo = 1
                                    AND et.sEstado = 'F'
                                 ORDER BY et.nIdEtapaTramite DESC
                              ) */
      FROM SimTramite t
      JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
      JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
      JOIN SImDependencia d ON t.sIdDependencia = d.sIdDependencia
      WHERE
         t.bCancelado = 0
         -- AND t.bCulminado = 1
         -- AND ti.sEstadoActual = 'A'
         -- AND d.sIdDependencia IN ('27', '112')
         -- AND t.nIdTipoTramite IN (34, 39, 55, 56, 57, 58, 61, 62, 65, 92, 105, 113, 126)
         /* AND t.sIdDependencia IN (
                                    SELECT j.sIdDependencia
                                    FROM BD_SIRIM_DEV.dbo.RimRNJefaturaZonal j
                                    WHERE j.sIdJefatura = 'JZLIMA'
         ) */

   ) t2
   WHERE
      t2.nAñoTramite BETWEEN 2017 AND 2021

) t3
PIVOT (
   COUNT(t3.sNumeroTramite) FOR t3.nAñoTramite IN ([2017], [2018], [2019], [2020], [2021])
) pv

-- 2.3 Aprobados:
-- 2.3.1 tmp
DROP TABLE IF EXISTS #tmp_inm_aprob
SELECT 
   f.sNumeroTramite,
   f.sTipoTramite,
   f.sEstadoTramite,
   f.Dependencia,
   f.nAñoEtapaActual

   INTO #tmp_inm_aprob
FROM (

   SELECT
         t.sNumeroTramite,
         [sTipoTramite] = UPPER(tt.sDescripcion),
         [sEstadoTramite] = (
                              CASE ti.sEstadoActual
                                 WHEN 'A' THEN 'APROBADO'
                                 WHEN 'B' THEN 'ABANDONO'
                                 WHEN 'D' THEN 'DENEGADO'
                                 WHEN 'E' THEN 'DESISTIDO'
                                 WHEN 'N' THEN 'NO PRESENTADA'
                                 WHEN 'R' THEN 'ANULADO'
                                 WHEN 'P' THEN 'PENDIENTE'
                                 -- WHEN 'E' THEN ''
                              END
                           ),
         [Dependencia] = d.sNombre,
         [nAñoEtapaActual] = DATEPART(YYYY, et.dFechaHoraFin),
         [#] = ROW_NUMBER() OVER (PARTITION BY t.sNumeroTramite ORDER BY et.nIdEtapaTramite DESC)

   FROM SimTramite t
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
   JOIN SimEtapaTramiteInm et ON t.sNumeroTramite = et.sNumeroTramite
   WHERE
      t.bCancelado = 0
      -- AND ti.sEstadoActual = 'A'
      AND et.bActivo = 1
      AND et.sEstado = 'F'

) f
WHERE f.[#] = 1


-- 2.3.1 Final:
SELECT pv.* 
FROM (
   SELECT a.* 
   FROM #tmp_inm_aprob a
   WHERE
      a.nAñoEtapaActual BETWEEN 2017 AND 2021
) f
PIVOT (
   COUNT(f.sNumeroTramite) FOR f.nAñoEtapaActual IN ([2017], [2018], [2019], [2020], [2021])
) pv


-- 2.1 Resumen: NAC
SELECT pv.* 
FROM (

   SELECT t2.* 
   FROM (

      SELECT
         t.sNumeroTramite,
         [sTipoTramite] = tt.sDescripcion,
         /* [sEstadoTramite] = (
                              CASE ti.sEstadoActual
                                 WHEN 'A' THEN 'APROBADO'
                                 WHEN 'B' THEN 'ABANDONO'
                                 WHEN 'D' THEN 'DENEGADO'
                                 WHEN 'E' THEN 'DESISTIDO'
                                 WHEN 'N' THEN 'NO PRESENTADA'
                                 WHEN 'R' THEN 'ANULADO'
                                 WHEN 'P' THEN 'PENDIENTE'
                                 -- WHEN 'E' THEN ''
                              END
                           ), */
         -- [Dependencia] = d.sNombre,
         [nAñoEtapaActual] = (
                                 SELECT
                                    TOP 1
                                    DATEPART(YYYY, et.dFechaHoraFin)
                                 FROM SimEtapaTramiteNac et
                                 WHERE
                                    et.sNumeroTramite = t.sNumeroTramite 
                                    AND et.bActivo = 1
                                    AND et.sEstado = 'F'
                                 ORDER BY et.nIdEtapaTramite DESC
                              ),
         [nMesEtapaActual] = (
                                 SELECT
                                    TOP 1
                                    DATEPART(MM, et.dFechaHoraFin)
                                 FROM SimEtapaTramiteNac et
                                 WHERE
                                    et.sNumeroTramite = t.sNumeroTramite 
                                    AND et.bActivo = 1
                                    AND et.sEstado = 'F'
                                 ORDER BY et.nIdEtapaTramite DESC
                              )
      FROM SimTramite t
      JOIN SimTramiteNac tn ON t.sNumeroTramite = tn.sNumeroTramite
      JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
      JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
      WHERE
         t.bCancelado = 0
         -- AND t.bCulminado = 1
         AND tn.sEstadoActual = 'A'
         AND t.nIdTipoTramite IN (69, 71, 72, 76, 78, 79, 80, 86, 127, 73, 75)

   ) t2
   WHERE 
      t2.nAñoEtapaActual = 2019

) t3
PIVOT (
   COUNT(t3.sNumeroTramite) FOR t3.nMesEtapaActual IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv


-- 2.1 Salidas
SELECT pv.*
FROM (

   SELECT 
      mm2.uIdPersona,
      [Tipo Movimiento] = mm2.sTipo,
      [Año Control] = DATEPART(YYYY, mm2.dFechaControl),
      [Pais Nacionalidad] = mm2.sIdPaisNacionalidad,
      [Pais Movimiento] = mm2.sIdPaisMov
   FROM (

      SELECT
         mm.*,
         [nOrden] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sIdPaisNacionalidad = 'PER'
         AND mm.sTipo = 'S'
         AND mm.sIdPaisMov = 'MEX'
         AND mm.dFechaControl >= '2023-01-01 00:00:00.000'

   ) mm2
   WHERE
      mm2.nOrden = 1

) mm3
PIVOT (
   COUNT(mm3.uIdPersona) FOR mm3.[Año Control] IN ([2023], [2024])
) pv


-- 2.1 Salidas sin retorno ...
SELECT pv.* 
FROM (

   SELECT 
      mm2.uIdPersona,
      [Tipo Movimiento] = mm2.sTipo,
      [Año Control] = DATEPART(YYYY, mm2.dFechaControl),
      [Pais Nacionalidad] = mm2.sIdPaisNacionalidad,
      [Pais Movimiento] = mm2.sIdPaisMov
   FROM (

      SELECT
         mm.*,
         [nOrden] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sIdPaisNacionalidad = 'PER'
         AND mm.sIdPaisMov = 'MEX'
         AND mm.dFechaControl >= '2023-01-01 00:00:00.000'

   ) mm2
   WHERE
      mm2.nOrden = 1
      AND mm2.sTipo = 'S'

) mm3
PIVOT (
   COUNT(mm3.uIdPersona) FOR mm3.[Año Control] IN ([2023], [2024])
) pv


-- Personas: SimMovMigra
-- 2.1 Salidas
SELECT pv.* 
FROM (

   SELECT 
      mm2.uIdPersona,
      [Tipo Movimiento] = mm2.sTipo,
      -- [Año Control] = DATEPART(YYYY, mm2.dFechaControl),
      [Pais Nacionalidad] = mm2.sIdPaisNacionalidad
      -- [Pais Movimiento] = mm2.sIdPaisMov
   FROM (

      SELECT
         mm.*,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sIdPaisNacionalidad = 'SAL' -- SAL ↔ EL SALVADOR ↔ SALVADOREÑA
         AND mm.dFechaControl >= '2023-12-23 00:00:00.000'

   ) mm2
   WHERE
      mm2.[#] = 1

) mm3
PIVOT (
   COUNT(mm3.uIdPersona) FOR mm3.[Tipo Movimiento] IN ([E], [S])
) pv

-- Test
SELECT * 
FROM SimPais p WHERE p.sNombre LIKE '%sal%'