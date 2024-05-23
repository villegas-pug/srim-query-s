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
   

-- 2
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
   [Calidad Migratoria] = COALESCE(cm.sDescripcion, 'Aún no ha sido ingresado o el trámite no establece una Calidad Migratoria'),
   [Etapa Actual] = e.sDescripcion,
   [Etapa Actual(SimEtapaTramiteInm)] = (
                                             SELECT 
                                                TOP 1 
                                                e.sDescripcion
                                             FROM SimEtapaTramiteInm et
                                             JOIN SimEtapa e2 ON et.nIdEtapa = e2.nIdEtapa
                                             WHERE
                                                et.sNumeroTramite = t.sNumeroTramite 
                                                AND et.bActivo = 1
                                             ORDER BY et.nIdEtapaTramite DESC
                                       ),
   [Estado Etapa Actual(SimEtapaTramiteInm)] = (
                                                      SELECT 
                                                         TOP 1 
                                                         et.sEstado
                                                      FROM SimEtapaTramiteInm et
                                                      WHERE
                                                         et.sNumeroTramite = t.sNumeroTramite 
                                                         AND et.bActivo = 1
                                                      ORDER BY et.nIdEtapaTramite DESC
                                                )
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SImDependencia d ON t.sIdDependencia = d.sIdDependencia
LEFT JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
LEFT JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND d.sIdDependencia IN ('27', '112')
   AND ti.sEstadoActual = 'P'



-- Peruanos salieron a México

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