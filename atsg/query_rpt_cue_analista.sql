USE SIM
GO


-- 1. CUE `tmp`
DROP TABLE IF EXISTS BD_SIRIM_DEV.dbo.tmp_cue_analisis
SELECT

   [Tipo de Documento] = ISNULL(ci.sIdDocumento, ''),
   [Número de documento] = ISNULL(ci.sNumDocumento, ''),
   [Nombres] = ci.sNombre,
   [Apellido 1] = ci.sPrimerApellido,
   [Apellido 2] = ci.sSegundoApellido,
   [Sexo] = '',
   [Fecha Nacimiento] = '',
   [Estado Civil] = '',
   [Pais Nacimiento] = '',
   [Pais Nacionalidad] = ci.sIdPaisNacionalidad,
   [Calidad Migratoria] = (
                              SELECT cm.sDescripcion
                              FROM SimPersona pe
                              JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
                              WHERE pe.uIdPersona = ci.uIdPersona
   ),

   [Información adicional 1 - Num Solicitud Cue] = s.sNumSolicitudCue,
   [Información adicional 2-Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
   [Información adicional 3 - Nombre de trámite] = tt.sDescripcion,
   [Información adicional 4 - N° Trámite] = s.sNumeroTramite,
   [Información adicional 5 - Última Etapa] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
   [Información adicional 6  - Estado] = (
                              CASE
                                 WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                 WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                 WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                 WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                              END
                           ),
   [Información adicional 7 - Usuario Análisis] = (
                           CASE WHEN s.nIdEtapaCUE = 3
                              THEN (
                                       SELECT
                                          TOP 1 
                                          CAST(
                                                ISNULL(
                                                         (SELECT sLogin FROM SimUsuario WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS INT)),
                                                         ''
                                                      ) AS VARCHAR(10)
                                          ) 
                                       FROM SimEtapaSolicitudCUE E
                                       WHERE 
                                          e.nIdSolicitudCUE = S.nIdSolicitudCue 
                                          AND e.nIdEtapaCUE = 2 
                                          AND (e.sEstado ='F' OR E.sEstado ='S') 
                                          AND e.bactivo = 1 
                                       ORDER BY nidetapaSolicue DESC
                                    )
                              ELSE
                                    CASE WHEN s.nIdEtapaCUE = 2 THEN -- ANALISIS
                                       CASE 
                                          WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY e.nIdEtapaSolicue DESC) --queda
                                          WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY e.nIdEtapaSolicue DESC) --queda
                                          WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador = CAST(s.nIdOperadorCue AS INT)) 
                                          WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador = CAST(s.nIdOperadorCue AS INT)) 
                                       END
                                    END
                           END
   ),
   [Información adicional 8 - Usuario Evaluador] = (
                           CASE 
                              WHEN s.nIdEtapaCUE = 3 THEN -- EVALUACION
                                 CASE 
                                    WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                              SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                      WHERE 
                                                                                                            nIdOperador= CAST(e.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                              FROM SimEtapaSolicitudCUE E 
                                                                              WHERE 
                                                                                    e.nIdSolicitudCUE = s.nIdSolicitudCue 
                                                                                    AND e.nIdEtapaCUE = 3 
                                                                                    AND e.sEstado ='F' 
                                                                                    AND e.bactivo = 1 
                                                                                 ORDER BY e.nIdEtapaSoliCUE DESC
                                                                           )
                                    WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(s.nIdOperadorCue AS INT)) 
                                 END
                              ELSE ''
                           END
   ),
   [Información adicional 9 - Acción de Evaluación] = '',
   [Información adicional 10 - Validación de Huellas] = IIF(ci.bTareaValidacionHuellas = 1, 'SI', 'NO'),
   [Información adicional 11 - N° CUE] = cue.sCodigoCue,
   [Información adicional 12 - Dígito Verificación] = '',
   [Información adicional 13 - Unificación] = IIF(ci.bUnionIdPersona = 1, 'SI', 'NO'),
   [Información adicional 14 - Origen de Coincidencia] = ci.sOrigenBusqueda,
   [Información adicional 15 - Huellas Revisadas] = IIF(ci.bHuellasRevisadas = 1, 'SI', 'NO'),

   -- Criterios Analisis:
   [Criterio de análisis 2 - Cantidad Coincidencias (CUE)] = (
                                                                  SELECT COUNT(1) FROM SimCoincidenciasIdentidadesCUE ci
                                                                  WHERE 
                                                                     ci.bActivo = 1
                                                                     AND ci.nIdSolicitudCue = s.nIdSolicitudCue
   ),
   [Criterio de análisis 3 - Observaciones] = (
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
   [Fecha Analisis ] = (

               CASE
                  WHEN s.nIdEtapaCUE = 3
                  THEN (
                           SELECT
                              TOP 1 e.dFechaHoraFin
                           FROM SimEtapaSolicitudCUE e
                           WHERE 
                              e.nIdSolicitudCUE = s.nIdSolicitudCue 
                              AND e.nIdEtapaCUE = 2 
                              AND (e.sEstado = 'F' OR E.sEstado = 'S') 
                              AND e.bactivo = 1 
                           ORDER BY e.nIdEtapaSoliCue DESC
                        )
                  ELSE
                        CASE WHEN s.nIdEtapaCUE = 2 THEN -- ANALISIS
                           CASE 
                              WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 e.dFechaHoraFin FROM SimEtapaSolicitudCUE e WHERE e.nIdSolicitudCUE = s.nIdSolicitudCue AND e.nIdEtapaCUE = 2 AND e.sEstado = 'F' AND e.bactivo = 1 ORDER BY e.nIdEtapaSoliCUE DESC)
                              WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 e.dFechaHoraFin FROM SimEtapaSolicitudCUE e WHERE e.nIdSolicitudCUE = s.nIdSolicitudCue AND e.nIdEtapaCUE = 2 AND E.sEstado ='S' AND e.bactivo = 1 ORDER BY e.nIdEtapaSoliCUE DESC)
                              WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT TOP 1 e.dFechaHoraInicio FROM SimEtapaSolicitudCUE e WHERE e.nIdSolicitudCUE = s.nIdSolicitudCue AND e.nIdEtapaCUE = 2 AND E.sEstado ='I' AND e.bactivo = 1 ORDER BY e.nIdEtapaSoliCUE DESC) 
                              WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT TOP 1 e.dFechaHoraFin FROM SimEtapaSolicitudCUE e WHERE e.nIdSolicitudCUE = s.nIdSolicitudCue AND e.nIdEtapaCUE = 2 AND E.sEstado ='O' AND e.bactivo = 1 ORDER BY e.nIdEtapaSoliCUE DESC) 
                           END
                        END
               END
   ),
   [Fecha Evaluacion] = (
                  CASE 
                     WHEN s.nIdEtapaCUE = 3 THEN -- EVALUACION
                        CASE 
                           WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                     SELECT TOP 1 e.dFechaHoraFin
                                                                     FROM SimEtapaSolicitudCUE e
                                                                     WHERE 
                                                                           e.nIdSolicitudCUE = s.nIdSolicitudCue 
                                                                           AND e.nIdEtapaCUE = 3 
                                                                           AND e.sEstado ='F' 
                                                                           AND e.bactivo = 1 
                                                                        ORDER BY nidetapaSolicue DESC
                                                                  )
                           WHEN s.sEstadoActualSoliCUE = 'I' THEN (
                                                                     SELECT TOP 1 e.dFechaHoraFin
                                                                     FROM SimEtapaSolicitudCUE e
                                                                     WHERE 
                                                                           e.nIdSolicitudCUE = s.nIdSolicitudCue 
                                                                           AND e.nIdEtapaCUE = 3 
                                                                           AND e.sEstado ='I' 
                                                                           AND e.bactivo = 1 
                                                                        ORDER BY nidetapaSolicue DESC
                           )
                        END
                  END
   )

   INTO BD_SIRIM_DEV.dbo.tmp_cue_analisis
FROM SimSolicitudCUE s
JOIN SimCodigoUnicoExtranjero cue ON s.nIdCue = cue.nIdCue
LEFT JOIN SimCoincidenciasIdentidadesCUE ci ON ci.nIdSolicitudCue = s.nIdSolicitudCue
JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
WHERE 
   s.bActivo = 1
   AND ci.bActivo = 1

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_cue_analisis_analisis
   ON BD_SIRIM_DEV.dbo.tmp_cue_analisis([Información adicional 7 - Usuario Análisis])

CREATE NONCLUSTERED INDEX ix_tmp_cue_analisis_evaluacion 
   ON BD_SIRIM_DEV.dbo.tmp_cue_analisis([Información adicional 8 - Usuario Evaluador], [Fecha Evaluacion])



-- 2. usp:
/* CREATE OR ALTER PROCEDURE usp_cue_por_analista
(
   @analista VARCHAR(55),
   @idEtapa TINYINT,
   @fecIni DATETIME2,
   @fecFin DATETIME2

)
AS
BEGIN
   IF (@idEtapa = 2)
   BEGIN
      SELECT
         [Analista] = @analista,
         a.*,
         [Criterio de análisis 1 - Tipo Acción] = (SELECT e.sDescripcion FROM SimEtapaCUE e WHERE e.nIdEtapaCUE = @idEtapa)
      FROM BD_SIRIM_DEV.dbo.tmp_cue_analisis a
      WHERE
         a.[Información adicional 7 - Usuario Análisis] = @analista
         AND a.[Fecha Analisis] BETWEEN @fecIni AND @fecFin
   END
   ELSE IF(@idEtapa = 3)
   BEGIN
      SELECT
         [Analista] = @analista,
         a.*,
         [Criterio de análisis 1 - Tipo Acción] = (SELECT e.sDescripcion FROM SimEtapaCUE e WHERE e.nIdEtapaCUE = @idEtapa)
      FROM BD_SIRIM_DEV.dbo.tmp_cue_analisis a
      WHERE
         a.[Información adicional 8 - Usuario Evaluador] = @analista
         AND a.[Fecha Evaluacion] BETWEEN @fecIni AND @fecFin
   END
END */


-- 3. Final

/*
   Usr's:
      → ASALDARRIA
      → CALCANTARA
      → EORMACHEA
      → LCONTRERAS
      → MRODRIGUEZ
      → NPASTOR                                            

      → DLANEGRA
      → GCAMPOS
      → JPONCES
      → MBRAVOV
      → MCARRILLO
*/


EXEC usp_cue_por_analista 'CALCANTARA', 3, '2024-06-01 00:00:00.000', '2024-12-17 23:59:59.999'



SELECT COUNT(1)
FROM BD_SIRIM_DEV.dbo.tmp_cue_analisis a
WHERE
   a.[Información adicional 1 - Num Solicitud Cue] = '202400037891'

SELECT 
   uf.sLogin,
   es.*
FROM SimEtapaSolicitudCUE es
JOIN SimUsuario uf ON es.nIdUsrFinaliza = uf.nIdOperador
-- JOIN SimUsuario ua ON es.nIdUsrFinaliza = ue.nIdOperador
WHERE 
   es.nIdSolicitudCUE = (
                           SELECT s.nIdSolicitudCue
                           FROM SimSolicitudCUE s
                           WHERE s.sNumSolicitudCue = '202400038960'
   )











/*
   LBHERNANDE
   LBHERNANDEZ
*/


-- Analisis
UPDATE BD_SIRIM_DEV.dbo.tmp_cue_analisis
   SET [Información adicional 7 - Usuario Análisis] = 'LBHERNANDE'
WHERE
   [Información adicional 7 - Usuario Análisis] = 'LBHERNANDEZ'

-- Evaluacion
UPDATE BD_SIRIM_DEV.dbo.tmp_cue_analisis
   SET [Información adicional 8 - Usuario Evaluador] = 'LBHERNANDE'
WHERE
   [Información adicional 8 - Usuario Evaluador] = 'LBHERNANDEZ'

SELECT
   a.[Información adicional 7 - Usuario Análisis]
FROM BD_SIRIM_DEV.dbo.tmp_cue_analisis a
GROUP BY
   a.[Información adicional 7 - Usuario Análisis]
   

SELECT * 
FROM BD_SIRIM_DEV.dbo.tmp_cue_analisis a
   

