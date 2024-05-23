USE SIM
GO

/*

» Etapas
	→ Recepción CUE (F)
» Estados
	→ F: Finalizado
	→ S: Subsanado
	→ I: Iniciado
	→ O: Observado

[dbo].[SimDatosTramiteCUE]
[dbo].[SimCoincidenciasIdentidadesCUE]
[dbo].[SimDjIdentidadesPersonaCUE]
[dbo].[SimEtapaCUE]
[dbo].[SimEtapaSolicitudCUE]
[dbo].[SimLogCue]
[dbo].[SimPersonaCUE]
[dbo].[SimSolicitudCUE]
[dbo].[SimSolicitudObsCUE]
[dbo].[SimSolUnifiPersCUE] */

SELECT TOP 10 * FROM SimExtranjero
SELECT TOP 10 * FROM SimPersona
SELECT TOP 10 * FROM SimPersonaCUE
SELECT TOP 10 * FROM SimDatosTramiteCUE
SELECT TOP 10 * FROM SimSolicitudCUE

-- 1
-- nProcesoConicidencia 
-- nProcesoHuellas
EXEC sp_help SimCoincidenciasIdentidadesCUE
SELECT TOP 10 * FROM SimCoincidenciasIdentidadesCUE sci
WHERE sci.bBiometriaWsq = 0

-- 2
SELECT TOP 10 * FROM SimDatosTramiteCUE sci
SELECT TOP 10 * FROM SimCodigoUnicoExtranjero scue

-- 3. `usp` REPORTE DE SOLICITUDES Y COINCIDENCIAS ...
SELECT * FROM SimEtapaCUE
EXEC sp_helptext Usp_Sim_Inm_Listar_SolicitudCUEMatchFind
EXEC Usp_Sim_Inm_Listar_SolicitudCUEMatchFind '2024-01-01 00:00:00.000', '2024-01-30 23:59:59.999'
-- Usp_Sim_Cue_ObtenerCoincidencias

-- 1. ...
EXEC Usp_Sim_Inm_Listar_SolicitudCUEMatchFind '2024-01-01 00:00:00.000', '2024-01-30 23:59:59.999'
SELECT * FROM SimEtapaCUE
/*
   - nProcesoCoincidencias, nProcesoHuellas:
      → -2 Error
      → -1 Error
      →  0 No a empezado a procesas
      →  1 Procesado */
-- Buscar solicitud CUE

DROP TABLE IF EXISTS #tmp_solicitudes_cue
SELECT
   s.nIdSolicitudCue,
   [sNumSolicitudCue] = s.sNumSolicitudCue,
   [dFechaSolicitud] = CONVERT(VARCHAR(19),s.dFechaSolicitud,121),
   T.sDescripcion,
   S.sNumeroTramite,
   [nIdEtapaCUE] = (SELECT sDescripcion FROM SIMETAPACUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
   [sEstadoActualSoliCUE] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           ),
   [sLoginUsuarioA] = (-- nIdUsrInicia | ANALISIS
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
   [bEvaluacion] = (CASE WHEN c.bEvaluacion = 1 THEN 'SI' ELSE 'NO' END),
   [bTareaValidacionHuellas] = (CASE WHEN c.bTareaValidacionHuellas = 1 THEN 'SI' ELSE 'NO' END),
   [sCUE] = (
               case 
                  when ( (select count(*) from SimPersonaCUE z where z.uidpersona = c.uidpersona and z.bactivo = 1) = 1) 
                  then (SELECT k.sCodigoCue from SimCodigoUnicoExtranjero k inner join SimPersonaCUE z2 on z2.nidcue = k.nidcue where z2.uidpersona = c.uidpersona  and z2.bactivo = 1 and k.bactivo = 1) 
                  ELSE ('') 
               end
            ),
   [sNumeroIdentificador] = ( --cue.sNumeroIdentificador,
                              case 
                                 when ( (select count(*) from SimPersonaCUE z where z.uidpersona = c.uidpersona and z.bactivo = 1) = 1) 
                                    then (
                                             SELECT k.sNumeroIdentificador 
                                             from SimCodigoUnicoExtranjero k 
                                             inner join SimPersonaCUE z2 on z2.nidcue = k.nidcue 
                                             where 
                                                z2.uidpersona = c.uidpersona 
                                                and z2.bactivo = 1 
                                                and k.bactivo = 1
                                          ) 
                                    ELSE ''
                              end
                           ),
   [sIdDocumento] = ISNULL(C.sIdDocumento,''),
   [sNumDocumento] = ISNULL(C.sNumDocumento,''),
   C.sNombre,
   C.sPrimerApellido,
   C.sSegundoApellido,
   P.sSexo,
   [dFechaNacimiento] = CONVERT(VARCHAR(10),P.dFechaNacimiento,103),
   P.sIdPaisNacimiento,
   P.sIdPaisNacionalidad,
   [sCalidad] = (SELECT sDescripcion FROM SimCalidadMigratoria WHERE nIdCalidad= P.nIdCalidad),
   [bUnionIdPersona] = (CASE WHEN c.bUnionIdPersona=1 THEN 'SI' ELSE 'NO' END),
   [sOrigenBusqueda] = ISNULL(c.sOrigenBusqueda,''),
   [bHuellasRevisadas] = (CASE WHEN c.bHuellasRevisadas=1 THEN 'SI' ELSE 'NO' END),

   -- Aux
   [dFechaEtapaRecepcion(F)] = ''

   INTO #tmp_solicitudes_cue
FROM SimSolicitudCUE S
INNER JOIN SimCoincidenciasIdentidadesCUE C ON C.nIdSolicitudCue = S.nIdSolicitudCue
INNER JOIN SimPersona P ON P.uIdPersona = C.uIdPersona
INNER JOIN SimTipoTramite T ON T.nIdTipoTramite=S.nIdTipoTramite
LEFT JOIN SimPersonaCUE PC ON s.nidcue = pc.nidcue--PC.uIdPersona=P.uIdPersona
LEFT JOIN SimCodigoUnicoExtranjero CUE ON CUE.nIdCUE=PC.nIdCUE
WHERE 
   S.bActivo = 1
   AND C.bActivo = 1
   -- and s.dfechasolicitud >= @dtFechaInicio and s.dfechasolicitud < @dtFechaFinal											
   -- AND s.dFechaSolicitud <= '2024-02-08 23:59:59.999'
   -- AND s.nProcesoCoincidencias = 1
   -- AND s.nProcesoHuellas = 1
   AND s.nIdEtapaCUE = 1 -- 1 ↔ RECEPCIÓN SOLICITUD CUE
   -- AND s.nIdEtapaCUE = 2 -- 2	↔ ANÁLISIS
   -- AND s.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
GROUP BY
   s.sNumSolicitudCue, 
   s.dFechaSolicitud,
   T.sDescripcion, 
   S.sNumeroTramite,
   S.nIdEtapaCUE,
   s.sEstadoActualSoliCUE, 
   S.nIdSolicitudCue,
   S.nIdOperadorCue,
   c.bEvaluacion,
   c.bTareaValidacionHuellas,
   c.uidpersona,
   c.uidpersona,
   C.sIdDocumento,
   C.sNumDocumento,
   C.sNombre, 
   C.sPrimerApellido,
   C.sSegundoApellido,
   P.sSexo,
   P.dFechaNacimiento,
   P.sIdPaisNacimiento,
   P.sIdPaisNacionalidad,
   P.nIdCalidad,
   c.bUnionIdPersona,
   c.sOrigenBusqueda,
   c.bHuellasRevisadas

-- 2. Filtro por estado etapa ...
SELECT s.* FROM #tmp_solicitudes_cue s
WHERE EXISTS (

   SELECT 1 FROM (
      SELECT 
         ses.*, 
         [nOrden] = ROW_NUMBER() OVER (ORDER BY ses.nIdEtapaSoliCUE DESC)
      FROM SimEtapaSolicitudCUE ses
      WHERE
         ses.bActivo = 1
         AND ses.nIdSolicitudCUE = s.nIdSolicitudCue
         AND ses.nIdEtapaCUE = 1 -- 1 ↔ RECEPCIÓN
         -- AND ses.nIdEtapaCUE = 2 -- 2 ↔ ANALISIS
         -- AND ses.nIdEtapaCUE = 3 -- 3 ↔ EVALUACIÓN
   ) ses2
   WHERE
      ses2.nOrden = 1
      AND ses2.sEstado = 'I'

)
ORDER BY s.dFechaSolicitud ASC

-- Test ...
SELECT TOP 10 * 
FROM #tmp_solicitudes_cue ;




-- 2
EXEC sp_help SimSolicitudCUE
EXEC sp_help SimCoincidenciasIdentidadesCUE
SELECT TOP 10 * FROM SimVerificacionDactilarCue
SELECT TOP 10 * FROM SimPersonaCUE
SELECT TOP 10 * FROM SimLogCue
SELECT TOP 10 * FROM SimCoincidenciasIdentidadesCUE
SELECT TOP 10 * FROM SimSolUnifiPersCUE




