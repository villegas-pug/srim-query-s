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
SELECT * FROM #tmp_solicitudes_cue


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
   AND s.dFechaSolicitud <= '2024-06-13 23:59:59.999'
   -- AND s.dFechaSolicitud BETWEEN '2024-01-23 00:00:00.000' AND '2024-01-31 23:59:59.999' -- Del 23ENE2024 al 31ENE2024
   -- AND s.dFechaSolicitud BETWEEN '2024-04-04 00:00:00.000' AND '2024-04-04 23:59:59.999' -- Del 17FEB2024 AL 29FEB 2024
   AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
   -- AND s.nIdEtapaCUE = 2 -- ANALISIS
   -- AND s.nIdEtapaCUE = 3 -- EVALUACIÓN
   -- AND s.sEstadoActualSoliCUE = 'I'
   AND s.sEstadoActualSoliCUE = 'F'
   -- AND s.sEstadoActualSoliCUE IN ('O', 'S', 'F')
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


--> 2.3 Reporte coordinador CUE kquispe ...
/*
   -	Observados (los que en la etapa de evaluación fueron observados)
   -	N° de coincidencias 
   -	N° de registros que deben ser unificados <-
   -	N° de registros indicados que se les debe asignar el mimo cue
   -	Presentó DJ (SI/NO)*/
DROP TABLE IF EXISTS #tmp_cue_eval
SELECT
   [Id Solicitud Cue] = s.nIdSolicitudCue,
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
                                       WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS INT)) 
                                       WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS INT)) 
                                    END							
                                 ELSE '' 
                                 END 	
                        END
   ),
   [Documento] = ISNULL(s.sIdDocumento, ''),
   [Num Documento] = ISNULL(s.sNumDocumento, ''),
   [Nombre] = s.sNombre,
   [Primer Apellido] = s.sPrimerApellido,
   [Segundo Apellido] = s.sSegundoApellido,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Estado Civil] = p.sIdEstadoCivil,
   [Pais Nacimiento] = p.sIdPaisNacimiento,
   [Pais Nacionalidad] = p.sIdPaisNacionalidad,
   [Num Solicitud Cue] = s.sNumSolicitudCue,
   [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Número Trámite] = s.sNumeroTramite,
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
   [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
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
   /* [Fecha Evaluación (I)] = (
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
                              ), */
   /* [Login Usuario Evaluación] = ( -- nIdUsrFinaliza
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
   ), */
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
   ),
   [Detalle Observacion] = (
                              REPLACE(
                                 REPLACE(
                                    (
                                       SELECT so.sObservacion
                                       FROM SimSolicitudObsCUE so
                                       WHERE 
                                          so.bActivo = 1
                                          AND so.nIdEtapaCUE = 3 -- Evaluación
                                          AND so.nIdSolicitudCUE = s.nIdSolicitudCUE
                                       FOR XML PATH('')
                                    ),
                                    '<sObservacion>',
                                    'Observación: '
                                 ),
                                 '</sObservacion>',
                                 '; '
                              )
   ),
   [Estado Actual Soli CUE] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           )
   /* s.nProcesoCoincidencias,
   s.nProcesoCoincidencias */
   -- Etapa: EVALUACIÓN
   INTO #tmp_cue_eval
FROM SimSolicitudCUE s
JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
JOIN SimPersona p ON s.uIdPersona = p.uIdPersona
WHERE 
   s.bActivo = 1
   -- AND s.dFechaSolicitud BETWEEN '2024-01-23 00:00:00.000' AND '2024-01-31 23:59:59.999' -- Del 23ENE2024 al 31ENE2024
   -- AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
   -- AND s.nIdEtapaCUE = 2 -- ANALISIS
   AND s.nIdEtapaCUE = 3 -- EVALUACIÓN
   AND s.sEstadoActualSoliCUE = 'F'
   -- AND s.sEstadoActualSoliCUE IN ('O', 'S', 'F')
   -- AND s.sEstadoActualSoliCUE = 'O' -- OBSERVADO
   -- AND (s.nProcesoCoincidencias != 1 OR s.nProcesoHuellas != 1)
   AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)
   AND s.sNumSolicitudCue = '202400057030'

--> 2.3.1: Final
SELECT e.* 
FROM #tmp_cue_eval e
WHERE 
   -- e.[Fecha Evaluación (F)] BETWEEN '2024-05-01 00:00:00.000' AND '2024-05-31 23:59:59.999'
   YEAR(e.[Fecha Evaluación (F)]) = 2024 AND MONTH(e.[Fecha Evaluación (F)]) = 6


-- Cantidad de solicitudes CUE, por etapas ...
SELECT
   [Etapa CUE] = e.sDescripcion,
   [Estado Actual] = (
                           CASE
                              WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                              WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                              WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                              WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                           END
                        ),
   [Total] = COUNT(1)
FROM SimSolicitudCUE s
JOIN SimEtapaCUE e ON s.nIdEtapaCUE = e.nIdEtapaCUE
WHERE 
   s.bActivo = 1
GROUP BY
   e.sDescripcion,
   CASE
      WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
      WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
      WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
      WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
   END
   


-- 3.0.0: CUE por meses
SELECT 
   [Etapa] = 'En recepción CUE',
   f.nTotal
FROM (

   SELECT -- Recepción CUE
      [nTotal] = COUNT(1)
   FROM SimSolicitudCUE s
   JOIN SimEtapaCUE e ON s.nIdEtapaCUE = e.nIdEtapaCUE
   WHERE 
      s.bActivo = 1
      AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
      AND s.sEstadoActualSoliCUE = 'F'
      -- AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)

) f

UNION ALL

SELECT 
   [Etapa] = 'Para Analisis CUE',
   f.nTotal
FROM (

   SELECT -- Recepción CUE
      [nTotal] = COUNT(1)
   FROM SimSolicitudCUE s
   JOIN SimEtapaCUE e ON s.nIdEtapaCUE = e.nIdEtapaCUE
   WHERE 
      s.bActivo = 1
      AND s.nIdEtapaCUE IN (1, 2)
      AND s.sEstadoActualSoliCUE = (
                                       CASE
                                          WHEN s.nIdEtapaCUE = 1 THEN 'F' -- RECEPCIÓN CUE(F)
                                          WHEN s.nIdEtapaCUE = 2 THEN 'I' -- ANALISIS(I)
                                       END
      )
      -- AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)

) f

UNION ALL

SELECT 
   [Etapa] = 'Para evaluación CUE',
   f.nTotal
FROM (

   SELECT -- Recepción CUE
      [nTotal] = COUNT(1)
   FROM SimSolicitudCUE s
   JOIN SimEtapaCUE e ON s.nIdEtapaCUE = e.nIdEtapaCUE
   WHERE 
      s.bActivo = 1
      AND s.nIdEtapaCUE IN (2, 3)
      AND s.sEstadoActualSoliCUE = (
                                       CASE
                                          WHEN s.nIdEtapaCUE = 2 THEN 'F' -- ANALISIS(F)
                                          WHEN s.nIdEtapaCUE = 3 THEN 'I' -- EVALUACION(I)
                                       END
      )
      -- AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)

) f


-- Identidades para unificación CUE:
-- 1.
EXEC sp_help SimCoincidenciasIdentidadesCUE
SELECT

   c.nIdIdentSoliCue,
   c.uIdPersona,
   c.nIdSolicitudCue,
   c.sNumeroTramite,
   c.sNombre,
   c.sPrimerApellido,
   c.sSegundoApellido,
   c.sIdPaisNacionalidad,
   c.dFechaHoraRegistro,
   c.sIdDocumento,
   [sNumDocumento] = CONCAT('''', c.sNumDocumento),
   [sNumSolicitudCue] = CONCAT('''', s.sNumSolicitudCue)

FROM [dbo].[SimCoincidenciasIdentidadesCUE] c
RIGHT JOIN SimSolicitudCUE s ON c.nIdSolicitudCue = s.nIdSolicitudCue
WHERE 
   -- c.bActivo = 1
   s.bActivo = 1
   AND c.bUnionIdPersona = 1
ORDER BY
   c.nIdSolicitudCue

-- 2.

SELECT f.*
FROM (

   SELECT
      c2.*,
      [#] = COUNT(1) OVER (PARTITION BY c2.uIdPersona),
      [nCoincidencias] = COUNT(1) OVER (PARTITION BY c2.sNumSolicitudCue),
      [sUnificar(IdenticoConPredecesor)] = (
                                             CASE
                                                WHEN COUNT(1) OVER (PARTITION BY c2.sIdPersona) >= 2 THEN 'SI'
                                                ELSE 'NO'
                                             END
      )
   FROM (

      SELECT

         [sIdPersona] = REPLACE(CONCAT(c.sNombre, c.sPrimerApellido, c.sSegundoApellido, c.sIdPaisNacionalidad), ' ', ''),
         c.nIdIdentSoliCue,
         c.uIdPersona,
         c.nIdSolicitudCue,
         c.sNumeroTramite,
         c.sNombre,
         c.sPrimerApellido,
         c.sSegundoApellido,
         c.sIdPaisNacionalidad,
         c.dFechaHoraRegistro,
         c.sIdDocumento,
         [sNumDocumento] = CONCAT('''', c.sNumDocumento),
         [sNumSolicitudCue] = (
                                 SELECT s.sNumSolicitudCue FROM SimSolicitudCUE s
                                 WHERE 
                                    s.nIdSolicitudCue = c.nIdSolicitudCue
         )

      FROM [dbo].[SimCoincidenciasIdentidadesCUE] c
      JOIN SimSolicitudCUE s ON c.nIdSolicitudCue = s.nIdSolicitudCue
      WHERE 
         s.bActivo = 1
         AND c.bActivo = 1
         AND c.bUnionIdPersona = 1

   ) c2

) f
WHERE
   f.[#] = 1 -- Registro único
   AND f.[nCoincidencias] >= 2



SELECT TOP 10 * FROM SimCoincidenciasIdentidadesCUE


SELECT mm.* 
FROM SimTramite t
JOIN SimMovMigra mm ON t.uIdPersona = mm.uIdPersona
WHERE
   t.sNumeroTramite = 'MR190025057'
ORDER BY
   mm.dFechaControl DESC



--> 2.4 Reporte con formato CUE ...

--> 2.4.1 
SELECT * FROM SimEtapaCUE


/* 
   Estados:
      'I' → 'INICIADO'
      'O' → 'OBSERVADO'
      'S' → 'SUBSANADO'
      'F' → 'FINALIZADO'

   Etapas:

      1 → RECEPCIÓN SOLICITUD CUE
      2 → ANÁLISIS
      3 → EVALUACIÓN                                                          */
SELECT
   -- COUNT(1)
   [Id Solicitud Cue] = s.nIdSolicitudCue,
   [Documento] = ISNULL(s.sIdDocumento, ''),
   [Num Documento] = ISNULL(s.sNumDocumento, ''),
   [Nombre] = s.sNombre,
   [Primer Apellido] = s.sPrimerApellido,
   [Segundo Apellido] = s.sSegundoApellido,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Estado Civil] = p.sIdEstadoCivil,
   [Pais Nacimiento] = p.sIdPaisNacimiento,
   [Pais Nacionalidad] = p.sIdPaisNacionalidad,
   [Num Solicitud Cue] = s.sNumSolicitudCue,
   [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
   [Número Trámite] = s.sNumeroTramite,
   [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE = e.nIdEtapaCUE),
   [Operador(Análisis/Evaluación)] = (
                                          SELECT CAST(sLogin AS VARCHAR(15)) FROM SimUsuario 
                                          WHERE 
                                                nIdOperador = CAST(e.nIdUsrFinaliza AS INT)
                                       ),

   [Fecha(Análisis/Evaluación)] = CAST(e.dFechaHoraFin AS DATE)

FROM SimSolicitudCUE s
JOIN SimEtapaSolicitudCUE e ON s.nIdSolicitudCUE = e.nIdSolicitudCUE
LEFT JOIN SimPersona p ON s.uIdPersona = p.uIdPersona
WHERE 
   s.bActivo = 1
   AND e.bActivo = 1
   AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)
   AND e.sEstado = 'F'
   AND e.nIdEtapaCUE IN (3)
   -- AND e.dFechaHoraFin BETWEEN '2024-10-01 00:00:00.000' AND '2024-10-31 23:59:59.999'
   AND s.sNumSolicitudCue = '202400071440'


-- CUE por meses

/* 
   Estados:
      'I' → 'INICIADO'
      'O' → 'OBSERVADO'
      'S' → 'SUBSANADO'
      'F' → 'FINALIZADO'

   Etapas:

      1 → RECEPCIÓN SOLICITUD CUE
      2 → ANÁLISIS
      3 → EVALUACIÓN 
                                                        */
-- 1. Meses
SELECT pv.* 
FROM (

   SELECT 
      s2.nIdSolicitudCue,
      [nMesEtapa] = DATEPART(MM, s2.dFechaHoraFin)
   FROM (

      SELECT
         s.nIdSolicitudCue,
         e.dFechaHoraFin,
         [#] = ROW_NUMBER() OVER (PARTITION BY e.nIdSolicitudCue ORDER BY e.nIdEtapaSoliCUE DESC)
      FROM SimSolicitudCUE s
      JOIN SimEtapaSolicitudCUE e ON s.nIdSolicitudCUE = e.nIdSolicitudCUE
      WHERE 
         s.bActivo = 1
         AND e.bActivo = 1
         AND e.nIdEtapaCUE = 3
         AND e.sEstado = 'F'
         AND e.dFechaHoraFin BETWEEN '2025-01-01 00:00:00.000' AND '2025-12-31 23:59:59.998'
         -- AND e.nIdUsrFinaliza = 7155
         
   ) s2
   WHERE
      s2.[#] = 1

) s3
PIVOT (
   COUNT(s3.nIdSolicitudCue) FOR s3.[nMesEtapa] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 2. Año
SELECT pv.* 
FROM (

   SELECT 
      s2.nIdSolicitudCue,
      [nAñoEtapa] = DATEPART(YYYY, s2.dFechaHoraFin)
   FROM (

      SELECT
         s.nIdSolicitudCue,
         dFechaHoraFin,
         [#] = ROW_NUMBER() OVER (PARTITION BY e.nIdSolicitudCue ORDER BY e.nIdEtapaSoliCUE DESC)
      FROM SimSolicitudCUE s
      JOIN SimEtapaSolicitudCUE e ON s.nIdSolicitudCUE = e.nIdSolicitudCUE
      WHERE 
         s.bActivo = 1
         AND e.bActivo = 1
         AND e.nIdEtapaCUE = 3
         AND e.sEstado = 'F'
         AND e.dFechaHoraFin >= '2023-10-01 00:00:00.000'
         -- AND e.nIdUsrFinaliza = 7155
         
   ) s2
   WHERE
      s2.[#] = 1

) s3
PIVOT (
   COUNT(s3.nIdSolicitudCue) FOR s3.[nAñoEtapa] IN ([2023], [2024])
) pv

-- 2
SELECT 
   f.sFechaEtapa,
   [nTotal] = COUNT(1)
FROM (
   SELECT
      s.nIdSolicitudCue,
      [sFechaEtapa] = FORMAT(e.dFechaHoraFin, 'yyyyMM'),
      [#] = ROW_NUMBER() OVER (PARTITION BY e.nIdSolicitudCue ORDER BY e.nIdEtapaSoliCUE DESC)
   FROM SimSolicitudCUE s
   JOIN SimEtapaSolicitudCUE e ON s.nIdSolicitudCUE = e.nIdSolicitudCUE
   WHERE 
      s.bActivo = 1
      AND e.bActivo = 1
      AND e.nIdEtapaCUE = 3
      AND e.sEstado = 'F'
) f
WHERE 
   f.[#] = 1
GROUP BY
   f.sFechaEtapa

-- 1
SELECT [Total CUE Evaluación(F)] = COUNT(1)
FROM SimSolicitudCUE s
WHERE
   s.bActivo = 1
   AND s.sEstadoActualSoliCUE = 'F'
   AND s.nIdEtapaCUE = 3 -- Evaluación


-- CALCANTARA | 4063
SELECT * 
FROM SimUsuario u
WHERE
   -- u.sNombre LIKE '%CONTRE%'
   u.sLogin LIKE 'LCONTRERAS'

-- CUE

-- 1
SELECT
   e.*
FROM SimSolicitudCUE s
JOIN SimEtapaSolicitudCUE e ON s.nIdSolicitudCUE = e.nIdSolicitudCUE
WHERE 
   s.bActivo = 1
   AND e.bActivo = 1
   AND e.nIdEtapaCUE = 3
   AND e.sEstado = 'I'
   AND s.sEstadoActualSoliCUE = 'F'
   AND e.nIdUsrFinaliza IS NULL

-- 2
SELECT
   s.*
FROM SimSolicitudCUE s
WHERE 
   s.bActivo = 1
   AND s.nIdEtapaCUE = 3
   AND s.sEstadoActualSoliCUE = 'F'
   AND EXISTS (
                  SELECT TOP 1 1 FROM SimEtapaSolicitudCUE e 
                  WHERE
                     e.nIdSolicitudCUE = s.nIdSolicitudCUE
                     AND e.bActivo = 1
                     AND e.nIdEtapaCUE = 3
                     AND e.sEstado = 'I'
                     AND e.nIdUsrFinaliza IS NULL
   )



SELECT 
   mm.sIdDependencia,
   COUNT(1) 
FROM SimMovMigra mm
WHERE 
   mm.sIdModuloDigita = 'SIM-MCM'
GROUP BY
   mm.sIdDependencia
ORDER BY 2 DESC