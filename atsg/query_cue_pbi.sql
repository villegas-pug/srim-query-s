USE SIM
GO

-- 1. Dashboard PBI ...
DROP TABLE IF EXISTS #tmp_solicitudes_cue
SELECT
   s.nIdSolicitudCue,
   [sNumSolicitudCue] = s.sNumSolicitudCue,
   [dFechaSolicitud] = CAST(s.dFechaSolicitud AS DATE),
   [sTipoTramite] = tt.sDescripcion,
   S.sNumeroTramite,
   [sEtapaCUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
   [sEstadoActualSoliCUE] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           ),
   -- ANALISIS
   [sLoginUsuarioA] = (-- nIdUsrInicia
                        CASE WHEN S.nIdEtapaCUE = 3
                           THEN (
                                    SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                            WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                    FROM SimEtapaSolicitudCUE E 
                                    WHERE 
                                       E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                       AND E.nIdEtapaCUE = 2 
                                       AND (E.sEstado ='F' OR E.sEstado ='S') 
                                       AND e.bactivo = 1 
                                    ORDER BY nidetapaSolicue DESC
                                 )
                           ELSE
                                 CASE WHEN S.nIdEtapaCUE = 2 THEN -- ANALISIS
                                    CASE 
                                       WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                       WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                    END							
                                 ELSE '' 
                                 END 	
                        END
   ),
   [sLoginUsuarioE] = ( -- nIdUsrFinaliza
                           CASE 
                              WHEN S.nIdEtapaCUE = 3 THEN -- EVALUACION
                                 CASE 
                                    WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                              SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                      WHERE 
                                                                                                            nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                              FROM SimEtapaSolicitudCUE E 
                                                                              WHERE 
                                                                                    E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                                                    AND E.nIdEtapaCUE = 3 
                                                                                    AND E.sEstado ='F' 
                                                                                    AND e.bactivo = 1 
                                                                                 ORDER BY nidetapaSolicue DESC
                                                                           )
                                    WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                 END
                              ELSE
                                 CASE 
                                    WHEN S.nIdEtapaCUE != 3 THEN ''
                                    ELSE '' 
                                 END 		
                           END
   ),
   -- Aux
   [sTieneCoincidencias] = (
                              IIF(
                                    EXISTS(
                                             SELECT 1 FROM SimCoincidenciasIdentidadesCUE ci
                                             WHERE 
                                                ci.bActivo = 1
                                                AND ci.nIdSolicitudCue = s.nIdSolicitudCue
                                    ),
                                    'SI',
                                    'NO'
                              )
                           ),

   -- Etapa: RECEPCIÓN SOLICITUD CUE
   [dFechaEtapaRecepcion(F)] = (
                                    SELECT ses2.dFechaHoraFin FROM (
                                       SELECT
                                          es.dFechaHoraFin,
                                          [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                       FROM SimEtapaSolicitudCUE es
                                       WHERE
                                          es.bActivo = 1
                                          AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                          AND es.nIdEtapaCUE = 1 -- 1 ↔ RECEPCIÓN
                                    ) ses2
                                    WHERE
                                       ses2.nOrden = 1
                              ),

   -- Etapa: ANALISIS
   [dFechaEtapaAnalisis(I)] = (
                                 SELECT 
                                    -- FORMAT(ses2.dFechaHoraInicio, 'yyyy-MM-dd HH:mm') 
                                    ses2.dFechaHoraInicio
                                 FROM (
                                    SELECT
                                       es.dFechaHoraInicio,
                                       [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                    FROM SimEtapaSolicitudCUE es
                                    WHERE
                                       es.bActivo = 1
                                       AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                       AND es.nIdEtapaCUE = 2 -- 2 ↔ ANALISIS
                                 ) ses2
                                 WHERE
                                    ses2.nOrden = 1
                              ),
   [dFechaEtapaAnalisis(F)] = (
                                    SELECT 
                                       -- FORMAT(ses2.dFechaHoraFin, 'yyyy-MM-dd HH:mm') 
                                       ses2.dFechaHoraFin
                                    FROM (
                                       SELECT
                                          es.dFechaHoraFin,
                                          [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                       FROM SimEtapaSolicitudCUE es
                                       WHERE
                                          es.bActivo = 1
                                          AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                          AND es.nIdEtapaCUE = 2 -- 2 ↔ ANALISIS
                                    ) ses2
                                    WHERE
                                       ses2.nOrden = 1
                                 ),
   
   -- Etapa: EVALUACIÓN
   [dFechaEtapaEvaluación(I)] = (
                                 SELECT ses2.dFechaHoraInicio FROM (
                                    SELECT
                                       es.dFechaHoraInicio,
                                       [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                    FROM SimEtapaSolicitudCUE es
                                    WHERE
                                       es.bActivo = 1
                                       AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                       AND es.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
                                 ) ses2
                                 WHERE
                                    ses2.nOrden = 1
                              ),
   [dFechaEtapaEvaluación(F)] = (
                                    SELECT ses2.dFechaHoraFin FROM (
                                       SELECT
                                          es.dFechaHoraFin,
                                          [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                       FROM SimEtapaSolicitudCUE es
                                       WHERE
                                          es.bActivo = 1
                                          AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                          AND es.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
                                    ) ses2
                                    WHERE
                                       ses2.nOrden = 1
                                 ),
   [nCantCoincidencias] = (
                              SELECT COUNT(1) FROM SimCoincidenciasIdentidadesCUE ci
                              WHERE 
                                 ci.bActivo = 1
                                 AND ci.nIdSolicitudCue = s.nIdSolicitudCue
   )

   INTO #tmp_solicitudes_cue
FROM SimSolicitudCUE s
JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
WHERE 
   S.bActivo = 1
   -- AND s.dfechasolicitud BETWEEN '2023-11-01 00:00:00.000' AND '2024-11-01 00:00:00.000'
   -- AND s.nProcesoCoincidencias = 1
   -- AND s.nProcesoHuellas = 1
   -- AND s.nIdEtapaCUE = 1 -- 1 ↔ RECEPCIÓN SOLICITUD CUE; 2	↔ ANÁLISIS; 3 ↔ EVALUACIÓN

-- Test ...
SELECT * 
FROM #tmp_solicitudes_cue


-- 2. Reporte coordinador CUE ...
/*
 ╔ nProcesoCoincidencias, nProcesoHuellas:
   → -2 Error
   → -1 Error
   →  0 No a empezado a procesas
   →  1 Procesado */
SELECT
   [Id Solicitud Cue] = s.nIdSolicitudCue,
   [Num Solicitud Cue] = s.sNumSolicitudCue,
   [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Número Trámite] = s.sNumeroTramite,

   [Nombre] = s.sNombre,
   [Primer Apellido] = s.sPrimerApellido,
   [Segundo Apellido] = s.sSegundoApellido,
   [Documento] = ISNULL(s.sIdDocumento, ''),
   [Num Documento] = ISNULL(s.sNumDocumento, ''),

   [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
   [Estado Actual Soli CUE] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           ),
   -- ANALISIS
   [Login Usuario Analisis] = (-- nIdUsrInicia
                        CASE WHEN S.nIdEtapaCUE = 3
                           THEN (
                                    SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                            WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                    FROM SimEtapaSolicitudCUE E 
                                    WHERE 
                                       E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                       AND E.nIdEtapaCUE = 2 
                                       AND (E.sEstado ='F' OR E.sEstado ='S') 
                                       AND e.bactivo = 1 
                                    ORDER BY nidetapaSolicue DESC
                                 )
                           ELSE
                                 CASE WHEN S.nIdEtapaCUE = 2 THEN -- ANALISIS
                                    CASE 
                                       WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                       WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                    END							
                                 ELSE '' 
                                 END 	
                        END
   ),
   [Login Usuario Evaluación] = ( -- nIdUsrFinaliza
                           CASE 
                              WHEN S.nIdEtapaCUE = 3 THEN -- EVALUACION
                                 CASE 
                                    WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                              SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                      WHERE 
                                                                                                            nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                              FROM SimEtapaSolicitudCUE E 
                                                                              WHERE 
                                                                                    E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                                                    AND E.nIdEtapaCUE = 3 
                                                                                    AND E.sEstado ='F' 
                                                                                    AND e.bactivo = 1 
                                                                                 ORDER BY nidetapaSolicue DESC
                                                                           )
                                    WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                 END
                              ELSE
                                 CASE 
                                    WHEN S.nIdEtapaCUE != 3 THEN ''
                                    ELSE '' 
                                 END 		
                           END
   )
   /* s.nProcesoCoincidencias,
   s.nProcesoCoincidencias */
   
FROM SimSolicitudCUE s
JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
WHERE 
   s.bActivo = 1
   -- AND s.dFechaSolicitud >= '2024-02-02 00:00:00.000'
   -- AND s.dFechaSolicitud BETWEEN '2024-01-23 00:00:00.000' AND '2024-01-31 23:59:59.999' -- Del 23ENE2024 al 31ENE2024
   -- AND s.dFechaSolicitud BETWEEN '2024-04-04 00:00:00.000' AND '2024-04-04 23:59:59.999' -- Del 17FEB2024 AL 29FEB 2024
   -- AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
   -- AND s.nIdEtapaCUE = 2 -- ANALISIS
   AND s.nIdEtapaCUE = 3 -- EVALUACIÓN
   -- AND s.sEstadoActualSoliCUE = 'I'
   -- AND s.sEstadoActualSoliCUE = 'F'
   AND s.sEstadoActualSoliCUE IN ('O', 'S', 'F')
   -- AND (s.nProcesoCoincidencias != 1 OR s.nProcesoHuellas != 1)
   AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)



-- 2.2 Reporte coordinador CUE: Por fecha etapa ...
SELECT s2.* 
FROM (

   SELECT
      [Id Solicitud Cue] = s.nIdSolicitudCue,
      [Num Solicitud Cue] = s.sNumSolicitudCue,
      [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
      [Tipo Tramite] = tt.sDescripcion,
      [Número Trámite] = s.sNumeroTramite,

      [Nombre] = s.sNombre,
      [Primer Apellido] = s.sPrimerApellido,
      [Segundo Apellido] = s.sSegundoApellido,
      [Documento] = ISNULL(s.sIdDocumento, ''),
      [Num Documento] = ISNULL(s.sNumDocumento, ''),

      [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
      [Estado Actual Soli CUE] = (
                                 CASE
                                    WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                    WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                    WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                    WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                                 END
                              ),
      -- ANALISIS
      [Login Usuario A] = (-- nIdUsrInicia
                           CASE WHEN S.nIdEtapaCUE = 3
                              THEN (
                                       SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                               WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                       FROM SimEtapaSolicitudCUE E 
                                       WHERE 
                                          E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                          AND E.nIdEtapaCUE = 2 
                                          AND (E.sEstado ='F' OR E.sEstado ='S') 
                                          AND e.bactivo = 1 
                                       ORDER BY nidetapaSolicue DESC
                                    )
                              ELSE
                                    CASE WHEN S.nIdEtapaCUE = 2 THEN -- ANALISIS
                                       CASE 
                                          WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                          WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                          WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                          WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                       END							
                                    ELSE '' 
                                    END 	
                           END
      ),
      [Login Usuario E] = ( -- nIdUsrFinaliza
                              CASE 
                                 WHEN S.nIdEtapaCUE = 3 THEN -- EVALUACION
                                    CASE 
                                       WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                                 SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                         WHERE 
                                                                                                               nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                                 FROM SimEtapaSolicitudCUE E 
                                                                                 WHERE 
                                                                                       E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                                                       AND E.nIdEtapaCUE = 3 
                                                                                       AND E.sEstado ='F' 
                                                                                       AND e.bactivo = 1 
                                                                                    ORDER BY nidetapaSolicue DESC
                                                                              )
                                       WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                    END
                                 ELSE
                                    CASE 
                                       WHEN S.nIdEtapaCUE != 3 THEN ''
                                       ELSE '' 
                                    END 		
                              END
      ),
      [dFechaEtapaAnalisis(F)] = (
                                       SELECT ses2.dFechaHoraFin FROM (
                                          SELECT
                                             es.dFechaHoraFin,
                                             [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                          FROM SimEtapaSolicitudCUE es
                                          WHERE
                                             es.bActivo = 1
                                             AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                             AND es.nIdEtapaCUE = 2 -- 2 ↔ ANALISIS
                                       ) ses2
                                       WHERE
                                          ses2.nOrden = 1
                                    )

   FROM SimSolicitudCUE s
   JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
   WHERE 
      s.bActivo = 1
      -- AND s.dFechaSolicitud >= '2024-02-02 00:00:00.000'
      -- AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
      AND s.nIdEtapaCUE = 2 -- ANALISIS
      -- AND s.nIdEtapaCUE = 3 -- EVALUACIÓN
      -- AND s.sEstadoActualSoliCUE = 'I'
      AND s.sEstadoActualSoliCUE = 'F'
      -- AND (s.nProcesoCoincidencias != 1 OR s.nProcesoHuellas != 1)
      AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)
) s2
WHERE
   -- s2.[dFechaEtapaAnalisis(F)] BETWEEN '2024-01-23 00:00:00.000' AND '2024-01-31 23:59:59.999' -- Del 23ENE2024 al 31ENE2024
   s2.[dFechaEtapaAnalisis(F)] BETWEEN '2024-02-01 00:00:00.000' AND '2024-02-29 23:59:59.999' -- Del 01FEB2024 al 29FEB2024


-- 2.3 Reporte coordinador CUE kquispe ...
/*
   -	Observados (los que en la etapa de evaluación fueron observados)
   -	N° de coincidencias 
   -	N° de registros que deben ser unificados <-
   -	N° de registros indicados que se les debe asignar el mimo cue
   -	Presentó DJ (SI/NO)*/
 
SELECT
   [Id Solicitud Cue] = s.nIdSolicitudCue,
   [Num Solicitud Cue] = s.sNumSolicitudCue,
   [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Número Trámite] = s.sNumeroTramite,

   [Nombre] = s.sNombre,
   [Primer Apellido] = s.sPrimerApellido,
   [Segundo Apellido] = s.sSegundoApellido,
   [Documento] = ISNULL(s.sIdDocumento, ''),
   [Num Documento] = ISNULL(s.sNumDocumento, ''),

   [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
   [Estado Actual Soli CUE] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           ),
   -- ANALISIS
   [Login Usuario Analisis] = (-- nIdUsrInicia
                        CASE WHEN S.nIdEtapaCUE = 3
                           THEN (
                                    SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                            WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                    FROM SimEtapaSolicitudCUE E 
                                    WHERE 
                                       E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                       AND E.nIdEtapaCUE = 2 
                                       AND (E.sEstado ='F' OR E.sEstado ='S') 
                                       AND e.bactivo = 1 
                                    ORDER BY nidetapaSolicue DESC
                                 )
                           ELSE
                                 CASE WHEN S.nIdEtapaCUE = 2 THEN -- ANALISIS
                                    CASE 
                                       WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                       WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                       WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                    END							
                                 ELSE '' 
                                 END 	
                        END
   ),
   [Login Usuario Evaluación] = ( -- nIdUsrFinaliza
                           CASE 
                              WHEN S.nIdEtapaCUE = 3 THEN -- EVALUACION
                                 CASE 
                                    WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                              SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                      WHERE 
                                                                                                            nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                              FROM SimEtapaSolicitudCUE E 
                                                                              WHERE 
                                                                                    E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                                                    AND E.nIdEtapaCUE = 3 
                                                                                    AND E.sEstado ='F' 
                                                                                    AND e.bactivo = 1 
                                                                                 ORDER BY nidetapaSolicue DESC
                                                                           )
                                    WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                 END
                              ELSE
                                 CASE 
                                    WHEN S.nIdEtapaCUE != 3 THEN ''
                                    ELSE '' 
                                 END 		
                           END
   ),
   /* s.nProcesoCoincidencias,
   s.nProcesoCoincidencias */
   -- Etapa: EVALUACIÓN
   [Fecha Evaluación (I)] = (
                                 SELECT ses2.dFechaHoraInicio FROM (
                                    SELECT
                                       es.dFechaHoraInicio,
                                       [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                    FROM SimEtapaSolicitudCUE es
                                    WHERE
                                       es.bActivo = 1
                                       AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                       AND es.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
                                 ) ses2
                                 WHERE
                                    ses2.nOrden = 1
                              ),
   [Fecha Evaluación (F)] = (
                                    SELECT ses2.dFechaHoraFin FROM (
                                       SELECT
                                          es.dFechaHoraFin,
                                          [nOrden] = ROW_NUMBER() OVER (ORDER BY es.nIdEtapaSoliCUE DESC)
                                       FROM SimEtapaSolicitudCUE es
                                       WHERE
                                          es.bActivo = 1
                                          AND es.nIdSolicitudCUE = s.nIdSolicitudCue
                                          AND es.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
                                    ) ses2
                                    WHERE
                                       ses2.nOrden = 1
                                 ),
   [Cantidad Coincidencias(CUE)] = (
                              SELECT COUNT(1) FROM SimCoincidenciasIdentidadesCUE ci
                              WHERE 
                                 ci.bActivo = 1
                                 AND ci.nIdSolicitudCue = s.nIdSolicitudCue
   ),
   [Cantidad Evaluación] = (
                              SELECT COUNT(1)
                              FROM SimCoincidenciasIdentidadesCUE c
                              WHERE 
                                 c.bActivo = 1
                                 AND c.bEvaluacion = 1
                                 AND c.nIdSolicitudCue = s.nIdSolicitudCue
                  ),
   [Cantidad Union Personas] = (
                                 SELECT COUNT(1)
                                 FROM SimCoincidenciasIdentidadesCUE c
                                 WHERE 
                                    c.bActivo = 1
                                    AND c.bUnionIdPersona = 1
                                    AND c.nIdSolicitudCue = s.nIdSolicitudCue
                  ),
   [¿Presentó DJ?] = (
                        IIF(
                           EXISTS(
                              SELECT TOP 1 1
                              FROM SimDjIdentidadesPersonaCUE dj
                              WHERE
                                 dj.bActivo = 1
                                 AND dj.sNumeroTramite = s.sNumeroTramite
                           ),
                           'Si',
                           'No'
                        )
                  ),
   [¿Observado en Evaluación?] = (
                                    IIF(
                                       EXISTS(
                                          SELECT TOP 1 1
                                          FROM SimSolicitudObsCUE so
                                          WHERE 
                                             so.bActivo = 1
                                             AND so.nIdEtapaCUE = 3 -- Evaluación
                                             AND so.nIdSolicitudCUE = s.nIdSolicitudCUE
                                       ),
                                       'Si',
                                       'No'
                                    )
                  )
   
FROM SimSolicitudCUE s
JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
WHERE 
   s.bActivo = 1
   -- AND s.dFechaSolicitud BETWEEN '2024-01-23 00:00:00.000' AND '2024-01-31 23:59:59.999' -- Del 23ENE2024 al 31ENE2024
   -- AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
   -- AND s.nIdEtapaCUE = 2 -- ANALISIS
   AND s.nIdEtapaCUE = 3 -- EVALUACIÓN
   -- AND s.sEstadoActualSoliCUE = 'I'
   AND s.sEstadoActualSoliCUE IN ('O', 'S', 'F')
   -- AND s.sEstadoActualSoliCUE = 'O' -- OBSERVADO
   -- AND (s.nProcesoCoincidencias != 1 OR s.nProcesoHuellas != 1)
   AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)


-- Test
SELECT c.* 
FROM SimCoincidenciasIdentidadesCUE c
JOIN SimSolicitudCUE s ON c.nIdSolicitudCue = s.nIdSolicitudCue
WHERE 
   c.bActivo = 1
   -- AND c.bEvaluacion = 1
   -- AND s.sNumSolicitudCue = '202300001593' -- 164
   AND s.sNumSolicitudCue = '202300000058' -- 70
   -- AND s.sNumSolicitudCue = '202300005792'
   -- AND s.sNumSolicitudCue = '202300001828'
   -- 202400025011

SELECT c.* 
FROM SimCoincidenciasIdentidadesCUE c
WHERE c.nIdSolicitudCue = 58

SELECT TOP 10 * 
FROM SimSolUnifiPersCUE

