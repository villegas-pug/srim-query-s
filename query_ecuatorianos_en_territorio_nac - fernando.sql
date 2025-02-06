USE SIM
GO

-- 1. 
DROP TABLE IF EXISTS #tmp_ult_mm_ecu
SELECT

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
      mm.sIdDependencia,
      pe.sIdPaisNacionalidad,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'

) mm2
WHERE
   mm2.[#] = 1

-- 1.2 Residentes
ALTER TABLE #tmp_ult_mm_ecu
   ADD nResidente INT

ALTER TABLE #tmp_ult_mm_ecu
   ADD dFechaVenRes DATETIME2

-- 2
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

-- 1.3 Final.
SELECT
   e.*
FROM #tmp_ult_mm_ecu e
JOIN SimMovMIgra mm_d ON e.[sIdMovMigra(sIdDatosIdenticos)] = mm_d.sIdMovMigratorio
WHERE
   e.sTipoMovimiento = 'E'
   AND e.[nResidente] > 1 -- Residencia vencida o Irregulares
   

