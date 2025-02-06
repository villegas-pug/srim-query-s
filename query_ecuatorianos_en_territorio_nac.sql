USE SIM
GO

-- 1. 
-- 1.1 Ultimo control de `ECU`
UPDATE #tmp_ult_mm_ecu
SET nAñosPermanencia = DATEDIFF(YYYY, DATEADD(DD, e.nPermanencia, e.dFechaControl), GETDATE())
FROM #tmp_ult_mm_ecu e

DROP TABLE IF EXISTS #tmp_ult_mm_ecu
SELECT
   -- TOP 100
   mm2.*,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())

   INTO #tmp_ult_mm_ecu
FROM (

   SELECT

      -- Control
      mm.sIdMovMigratorio,
      mm.uIdPersona,
      mm.dFechaControl,
      [sTipoMovimiento] = mm.sTipo,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.sIdDependencia,
      mm.nPermanencia,
      [nIdCalidadMM] = mm.nIdCalidad,

      -- Persona
      pe.sNombre,
      pe.sPaterno,
      pe.sMaterno,
      pe.sSexo,
      pe.dFechaNacimiento,
      pe.sIdPaisNacionalidad,
      [nIdCalidadPer] = pe.nIdcalidad,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      -- AND pe.sIdPaisNacionalidad = 'ECU'

) mm2
WHERE
   mm2.[#] = 1


-- 1.2. Inserta key's → [datos], [datos + doc] de agrupación
ALTER TABLE #tmp_ult_mm_ecu
   ADD sIdDatosIdenticos VARCHAR(1000)

ALTER TABLE #tmp_ult_mm_ecu
   ADD sIdDatosIdenticosDocViaje VARCHAR(1000)

UPDATE #tmp_ult_mm_ecu
   SET [sIdDatosIdenticos] = REPLACE(
                                 CONCAT(
                                          SOUNDEX(mm.sNombre), 
                                          SOUNDEX(mm.sPaterno), 
                                          SOUNDEX(mm.sMaterno), 
                                          mm.sSexo, 
                                          ISNULL(TRY_CAST(mm.dFechaNacimiento AS INT), ''), 
                                          mm.sIdPaisNacionalidad
                                 ),
                                 ' ',
                                 ''
                           ),
      [sIdDatosIdenticosDocViaje] = REPLACE(
                                       CONCAT(
                                                SOUNDEX(mm.sNombre), 
                                                SOUNDEX(mm.sPaterno), 
                                                SOUNDEX(mm.sMaterno), 
                                                mm.sSexo, 
                                                ISNULL(TRY_CAST(mm.dFechaNacimiento AS INT), ''), 
                                                mm.sIdPaisNacionalidad,
                                                mm.sIdDocumento,
                                                mm.sNumeroDoc
                                       ),
                                       ' ',
                                       ''
                                 )
FROM #tmp_ult_mm_ecu mm

-- 1.3 Residentes
ALTER TABLE #tmp_ult_mm_ecu
   ADD nResidente INT

ALTER TABLE #tmp_ult_mm_ecu
   ADD dFechaVenRes DATETIME2


UPDATE #tmp_ult_mm_ecu
   SET [nResidente] =  ( -- 1: CE Vigente
                           CASE
                              WHEN (
                                 EXISTS ( -- CE
                                          SELECT 1
                                          FROM SimCarnetExtranjeria ce
                                          WHERE 
                                             ce.uIdPersona = mm.uIdPersona
                                             AND ce.bAnulado = 0
                                             AND GETDATE() < ce.dFechaVencRes -- Vigente
                                 )
                                 OR 
                                 EXISTS (
                                       SELECT 1
                                       FROM SimCarnetPTP ce
                                       WHERE 
                                          ce.uIdPersona = mm.uIdPersona
                                          AND ce.bAnulado = 0
                                          AND GETDATE() < ce.dFechaVenc -- Vigente
                                    )
                              ) THEN 1 -- Residentes
                              WHEN (
                                 EXISTS ( -- CE
                                          SELECT 1
                                          FROM SimCarnetExtranjeria ce
                                          WHERE 
                                             ce.uIdPersona = mm.uIdPersona
                                             AND ce.bAnulado = 0
                                             AND GETDATE() >= ce.dFechaVencRes -- Vencido
                                 )
                                 OR 
                                 EXISTS (
                                       SELECT 1
                                       FROM SimCarnetPTP ce
                                       WHERE 
                                          ce.uIdPersona = mm.uIdPersona
                                          AND ce.bAnulado = 0
                                          AND GETDATE() >= ce.dFechaVenc -- Vencido
                                    )
                              ) THEN 2 -- Residencia vencida
                              ELSE 3 -- No residentes
                           END
   ),
   [dFechaVenRes] = (
                        CASE
                           WHEN (-- CE
                                    EXISTS (
                                             SELECT 1
                                             FROM SimCarnetExtranjeria ce
                                             WHERE 
                                                ce.uIdPersona = mm.uIdPersona
                                                AND ce.bAnulado = 0
                                                -- AND ce.dFechaEmision >= '2016-01-01 00:00:00.000'
                                    )
                                 ) THEN (
                                       SELECT TOP 1  ce.dFechaVencRes
                                       FROM SimCarnetExtranjeria ce
                                       WHERE 
                                          ce.uIdPersona = mm.uIdPersona
                                          AND ce.bAnulado = 0
                                       ORDER BY ce.dFechaEmision DESC
                                 )
                           WHEN ( -- CPP
                                    EXISTS ( -- CE
                                             SELECT 1
                                             FROM SimCarnetPTP ce
                                             WHERE 
                                                ce.uIdPersona = mm.uIdPersona
                                                AND ce.bAnulado = 0
                                    ) 
                                 ) THEN (
                                       SELECT TOP 1 ce.dFechaVenc
                                       FROM SimCarnetPTP ce
                                       WHERE 
                                          ce.uIdPersona = mm.uIdPersona
                                          AND ce.bAnulado = 0
                                       ORDER BY ce.dFechaEmision DESC
                                 )
                           ELSE NULL
                        END
   )
FROM #tmp_ult_mm_ecu mm

-- 1.4 ...
ALTER TABLE #tmp_ult_mm_ecu
   ADD [sIdMovMigra(sIdDatosIdenticos)] VARCHAR(55)

ALTER TABLE #tmp_ult_mm_ecu
   ADD [sIdMovMigra(sIdDatosIdenticosDocViaje)] VARCHAR(55)

ALTER TABLE #tmp_ult_mm_ecu
   ADD [nResidente(sIdDatosIdenticos)] INT

ALTER TABLE #tmp_ult_mm_ecu
   ADD [nResidente(sIdDatosIdenticosDocViaje)] INT

ALTER TABLE #tmp_ult_mm_ecu
   ADD [dFechaVenRes(sIdDatosIdenticos)] DATETIME2

ALTER TABLE #tmp_ult_mm_ecu
   ADD [dFechaVenRes(sIdDatosIdenticosDocViaje)] DATETIME2


DROP TABLE IF EXISTS #tmp_ult_mm_ecu_otros_registros
SELECT

   e.sIdMovMigratorio,
   [sIdMovMigra(sIdDatosIdenticos)] = LAST_VALUE(e.sIdMovMigratorio) OVER (
                                                                              PARTITION BY e.sIdDatosIdenticos 
                                                                              ORDER BY e.dFechaControl ASC
                                                                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                           ),
   [sIdMovMigra(sIdDatosIdenticosDocViaje)] = LAST_VALUE(e.sIdMovMigratorio) OVER (
                                                                                    PARTITION BY e.sIdDatosIdenticosDocViaje 
                                                                                    ORDER BY e.dFechaControl ASC
                                                                                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                              ),
   [nResidente(sIdDatosIdenticos)] = FIRST_VALUE(e.nResidente) OVER (
                                                                        PARTITION BY e.sIdDatosIdenticos
                                                                        ORDER BY e.dFechaVenRes DESC
                                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                     ),
   [nResidente(sIdDatosIdenticosDocViaje)] = FIRST_VALUE(e.nResidente) OVER (
                                                                              PARTITION BY e.sIdDatosIdenticosDocViaje
                                                                              ORDER BY e.dFechaVenRes DESC
                                                                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                           ),
   [dFechaVenRes(sIdDatosIdenticos)] = FIRST_VALUE(e.dFechaVenRes) OVER (
                                                                           PARTITION BY e.sIdDatosIdenticos
                                                                           ORDER BY e.dFechaVenRes DESC
                                                                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                        ),
   [dFechaVenRes(sIdDatosIdenticosDocViaje)] = FIRST_VALUE(e.dFechaVenRes) OVER (
                                                                                 PARTITION BY e.sIdDatosIdenticosDocViaje
                                                                                 ORDER BY e.dFechaVenRes DESC
                                                                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                              )
   INTO #tmp_ult_mm_ecu_otros_registros
FROM #tmp_ult_mm_ecu e

UPDATE #tmp_ult_mm_ecu
   SET [sIdMovMigra(sIdDatosIdenticos)] = o.[sIdMovMigra(sIdDatosIdenticos)],
       [sIdMovMigra(sIdDatosIdenticosDocViaje)] = o.[sIdMovMigra(sIdDatosIdenticosDocViaje)],
       [nResidente(sIdDatosIdenticos)] = o.[nResidente(sIdDatosIdenticos)],
       [nResidente(sIdDatosIdenticosDocViaje)] = o.[nResidente(sIdDatosIdenticosDocViaje)],
       [dFechaVenRes(sIdDatosIdenticos)] = o.[dFechaVenRes(sIdDatosIdenticos)],
       [dFechaVenRes(sIdDatosIdenticosDocViaje)] = o.[dFechaVenRes(sIdDatosIdenticosDocViaje)]
FROM #tmp_ult_mm_ecu e
JOIN #tmp_ult_mm_ecu_otros_registros o ON e.sIdMovMigratorio = o.sIdMovMigratorio

-- 1.4 Final.
DECLARE @dFechaCorte DATETIME = '2016-01-01 00:00:00.000'
SELECT
   e.*,

   [bOtroUltMov(DatosIdenticos)] = IIF(e.sIdMovMigratorio = e.[sIdMovMigra(sIdDatosIdenticos)], 0, 1),
   [bOtroUltMov(DatosIdenticosDocViaje)] = IIF(e.sIdMovMigratorio = e.[sIdMovMigra(sIdDatosIdenticosDocViaje)], 0, 1),

   -- Datos Identicos
   [dFechaControl(DatosIdenticos)] = mm_d.dFechaControl,
   [sTipo(DatosIdenticos)] = mm_d.sTipo,
   [sIdDocumento(DatosIdenticos)] = mm_d.sIdDocumento,
   [sNumeroDoc(DatosIdenticos)] = mm_d.sNumeroDoc,
   [nAñosPermanencia(DatosIdenticos)] = (
                                             CASE
                                                WHEN (e.[nResidente(sIdDatosIdenticos)] = 2) THEN (
                                                   CASE
                                                      WHEN (e.[dFechaVenRes(sIdDatosIdenticos)] < @dFechaCorte) THEN (
                                                         DATEDIFF(
                                                            YYYY,
                                                            DATEADD(DD, CAST(mm_d.nPermanencia AS INT), mm_d.dFechaControl),
                                                            GETDATE()
                                                         )
                                                      )
                                                      ELSE DATEDIFF(YYYY, e.[dFechaVenRes(sIdDatosIdenticos)], GETDATE())
                                                   END
                                                )
                                                WHEN (e.[nResidente(sIdDatosIdenticos)] = 3) THEN DATEDIFF(
                                                                                                      YYYY, 
                                                                                                      DATEADD(DD, CAST(mm_d.nPermanencia AS INT), mm_d.dFechaControl),
                                                                                                      GETDATE()
                                                                                                   )
                                             END
   ),

   -- Datos Identicos + Doc viaje
   [dFechaControl(DatosIdenticosDocViaje)] = mm_dv.dFechaControl,
   [sTipo(DatosIdenticosDocViaje)] = mm_dv.sTipo,
   [sIdDocumento(DatosIdenticosDocViaje)] = mm_dv.sIdDocumento,
   [sNumeroDoc(DatosIdenticosDocViaje)] = mm_dv.sNumeroDoc,
   [nAñosPermanencia(DatosIdenticosDocViaje)] = (
                                             CASE
                                                WHEN (e.[nResidente(sIdDatosIdenticosDocViaje)] = 2) THEN (
                                                   CASE
                                                      WHEN (e.[dFechaVenRes(sIdDatosIdenticosDocViaje)] < @dFechaCorte) THEN (
                                                         DATEDIFF(
                                                            YYYY, 
                                                            DATEADD(DD, CAST(mm_dv.nPermanencia AS INT), mm_dv.dFechaControl), 
                                                            GETDATE())
                                                      )
                                                      ELSE DATEDIFF(YYYY, e.[dFechaVenRes(sIdDatosIdenticosDocViaje)], GETDATE())
                                                   END
                                                )
                                                WHEN (e.[nResidente(sIdDatosIdenticosDocViaje)] = 3) THEN DATEDIFF(
                                                                                                               YYYY, 
                                                                                                               DATEADD(DD, CAST(mm_dv.nPermanencia AS INT), mm_dv.dFechaControl), 
                                                                                                               GETDATE()
                                                                                                         )
                                             END
   )

FROM #tmp_ult_mm_ecu e
JOIN SimMovMIgra mm_d ON e.[sIdMovMigra(sIdDatosIdenticos)] = mm_d.sIdMovMigratorio
JOIN SimMovMIgra mm_dv ON e.[sIdMovMigra(sIdDatosIdenticosDocViaje)] = mm_dv.sIdMovMigratorio
WHERE
   e.sTipoMovimiento = 'E'
   AND e.[nResidente(sIdDatosIdenticos)] > 1 -- Residencia vencida o Irregulares
   /* AND NOT EXISTS ( -- Nacionalización
                        SELECT 1
                        FROM SimTramite t
                        JOIN SimTramiteNac n ON t.sNumeroTramite = n.sNumeroTramite
                        WHERE 
                           t.bCancelado = 0
                           AND t.uIdPersona = e.uIdPersona
                           AND n.sEstadoActual IN ('P', 'A')
                           AND t.dFechaHora >= e.dFechaControl
   ) */

SELECT DATEDIFF(YYYY, DATEADD(DD, 180, GETDATE()), GETDATE())

SELECT TOP 10 *
FROM #tmp_ult_mm_ecu e

SELECT 
   [nResidente(sIdDatosIdenticos)] 
FROM #tmp_ult_mm_ecu e
GROUP BY 
   [nResidente(sIdDatosIdenticos)]

SELECT 
   e.nPermanencia
FROM #tmp_ult_mm_ecu e
WHERE
   e.sTipoMovimiento = 'E'
   AND e.[nResidente(sIdDatosIdenticos)] > 1 -- Residencia vencida o Irregulares
GROUP BY 
   e.nPermanencia


SELECT COUNT(1) FROM #tmp_ult_mm_ecu
WHERE
   [nResidente(sIdDatosIdenticos)] = 1