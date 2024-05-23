USE SIM
GO


/*
   bActivo
   0 → Habilitada
   1 → Inhabilitada
========================================================================================================================================== */

-- 1: `tmp` alertas analizadas ...
DROP TABLE IF EXISTS tmp_dnv_informativas_analizadas
SELECT 
   TOP 0
   [nId] = 99999,
   [sNombreBase] = REPLICATE('', 70),
   dnv.sNombre, dnv.sPaterno, dnv.sMaterno, dnv.sIdPaisNacionalidad, 
   [sDocInvalida] = REPLICATE('', 500), 
   [sMotivo] = REPLICATE('', 50), 
   [sTipoAlerta] = REPLICATE('', 50)
   INTO tmp_dnv_informativas_analizadas
FROM SimPersonaNoAutorizada dnv

-- 1.2: bak
-- SELECT * INTO BD_SIRIM.dbo.tmp_dnv_informativas_analizadas FROM tmp_dnv_informativas_analizadas a
SELECT COUNT(1) FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas
SELECT TOP 100 * FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas

-- 2: Insert alertas analizadas ...
-- INSERT INTO tmp_dnv_informativas_analizadas VALUES()

BEGIN TRAN
-- COMMIT TRAN
ROLLBACK TRAN

-- 3
-- 3.1: Final: Inserta dependencia y estado de alertas ...
DROP TABLE IF EXISTS #tmp_dnv_informativas_analizadas_final
SELECT 
   a.*,
   [sDependencia] = (
                        COALESCE(
                           (
                              SELECT
                                 TOP 1
                                 d.sNombre
                              FROM SimPersonaNoAutorizada dnv
                              JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
                              JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
                              JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
                              JOIN SimSesion s ON dnv.nIdSesion = s.nIdSesion
                              JOIN SimDependencia d ON s.sIdDependencia = d.sIdDependencia
                              WHERE
                                 stt.sDescripcion = 'ALERTA ES INFORMATIVA'
                                 AND a.sNombre = dnv.sNombre
                                 AND a.sPaterno = dnv.sPaterno
                                 AND a.sMaterno = dnv.sMaterno
                                 AND a.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
                                 AND a.sDocInvalida LIKE '%' + sdi.sNumDocInvalida + '%'
                                 AND a.sMotivo = smi.sDescripcion
                                 AND a.sTipoAlerta = stt.sDescripcion
                              ORDER BY dnv.dFechaHoraAud DESC

                           ),
                           'LIMA' 
                        )
   ),
   [sEstado] = (
                     COALESCE(
                        (
                           SELECT
                              TOP 1
                              [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado')
                           FROM SimPersonaNoAutorizada dnv
                           JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
                           JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
                           JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
                           WHERE
                              stt.sDescripcion = 'ALERTA ES INFORMATIVA'
                              AND a.sNombre = dnv.sNombre
                              AND a.sPaterno = dnv.sPaterno
                              AND a.sMaterno = dnv.sMaterno
                              AND a.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
                              AND a.sDocInvalida LIKE '%' + sdi.sNumDocInvalida + '%'
                              AND a.sMotivo = smi.sDescripcion
                              AND a.sTipoAlerta = stt.sDescripcion
                           ORDER BY dnv.dFechaHoraAud DESC
                        ),
                        'Inhabilitado'
                     )
   )
   INTO #tmp_dnv_informativas_analizadas_final
FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a

-- Test
SELECT * FROM #tmp_dnv_informativas_analizadas_final f WHERE f.sDependencia IS NULL

-- 3.1.1 Pivot final
SELECT pv.* 
FROM (
   SELECT 
      [sNombreBase] = f.sNombrebasee,
      f.sDependencia,
      f.sEstado,
      f.nId
   FROM #tmp_dnv_informativas_analizadas_final f
) f2
PIVOT (
   COUNT(f2.nId) FOR f2.sEstado IN ([Inhabilitado], [Habilitado])
) pv

-- 3.2: Final: Verifica alertas pendientes ...
DROP TABLE IF EXISTS #tmp_dnv_informativas_pendientes_final
SELECT 
   [nIdDNV] = dnv.nIdCorrela,
   dnv.nIdDocInvalidacion,
   sdi.dFechaEmision,
   dnv.sNombre,
   dnv.sPaterno,
   dnv.sMaterno,
   dnv.sIdPaisNacionalidad,
   sdi.sNumDocInvalida,
   [sMotivo] = smi.sDescripcion,
   [sTipoAlerta] = stt.sDescripcion,
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [sDependencia] = d.sNombre,
   sdi.sObservaciones
   INTO #tmp_dnv_informativas_pendientes_final
FROM SimPersonaNoAutorizada dnv
JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
LEFT JOIN SimSesion s ON dnv.nIdSesion = s.nIdSesion
LEFT JOIN SimDependencia d ON s.sIdDependencia = d.sIdDependencia
WHERE
   dnv.bActivo = 1 -- Inhabilitado
   AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'
   AND NOT EXISTS (
                     SELECT 1
                     FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a
                     WHERE
                        a.sNombre = dnv.sNombre
                        AND a.sPaterno = dnv.sPaterno
                        AND a.sMaterno = dnv.sMaterno
                        AND a.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
                        AND a.sDocInvalida LIKE '%' + sdi.sNumDocInvalida + '%'
                        AND a.sMotivo = smi.sDescripcion
                        AND a.sTipoAlerta = stt.sDescripcion
   )

-- Test
SELECT * 
FROM #tmp_dnv_informativas_pendientes_final

-- 3.3: Final: Verifica alertas pendientes ...
DROP TABLE IF EXISTS #tmp_dnv_informativas_habilitadas_final
SELECT 
   dnv.sNombre,
   dnv.sPaterno,
   dnv.sMaterno,
   dnv.sIdPaisNacionalidad,
   sdi.sNumDocInvalida,
   [Motivo] = smi.sDescripcion,
   [Tipo Alerta] = stt.sDescripcion,
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   dnv.dFechaHoraAud
   INTO #tmp_dnv_informativas_habilitadas_final
FROM SimPersonaNoAutorizada dnv
JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
WHERE
   dnv.bActivo = 0 -- Habilitado
   AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'
   -- AND sdi.dFechaEmision > '2023-08-07 00:00:00.000'
   AND dnv.dFechaHoraAud > '2023-08-07 00:00:00.000'
   
-- 3.3.1
SELECT f2.* FROM (

   SELECT
      *,
      [nDupl] = ROW_NUMBER() OVER (PARTITION BY 
                                             f.sNombre,
                                             f.sPaterno,
                                             f.sMaterno,
                                             f.sIdPaisNacionalidad
                                    ORDER BY f.sNombre)
   FROM #tmp_dnv_informativas_habilitadas_final f

) f2
WHERE f2.nDupl = 1


-- Test ...
SELECT 
   ( -- DNV
      SELECT 
         COUNT(1)
      FROM SimPersonaNoAutorizada dnv
      JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
      JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
      JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
      WHERE
         -- dnv.bActivo = 1 -- Inhabilitado
         stt.sDescripcion = 'ALERTA ES INFORMATIVA'
   )
   -
   (SELECT COUNT(1) FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a) -- Analizados

   
-- Buscar duplicados en dnv Analizados
SELECT * FROM (

   SELECT 
      a.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY 
                                          a.sNombre,
                                          a.sPaterno,
                                          a.sMaterno,
                                          a.sIdPaisNacionalidad,
                                          a.sDocInvalida,
                                          a.sMotivo,
                                          a.sTipoAlerta)
   FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a

) a2
WHERE
   a2.nDupl > 1
ORDER BY
   a2.nDupl DESC


SELECT COUNT(1) FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a

SELECT a.sIdPaisNacionalidad FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas a GROUP BY a.sIdPaisNacionalidad

SELECT
   f.sNombrebasee,
   [nTotal] = COUNT(1)
FROM BD_SIRIM.dbo.tmp_dnv_informativas_analizadas f
GROUP BY 
   f.sNombrebasee
ORDER BY 1 ASC, 2 DESC

-- Final ...
SELECT pv.* FROM (

   SELECT 
      [Base] = UPPER(a.sNombrebasee),
      a.sEstado,
      a.nId
   FROM #tmp_dnv_informativas_analizadas_final a

) AS dnv
PIVOT (
   COUNT(dnv.nId) FOR dnv.sEstado IN ([Habilitado], [Inhabilitado])
) pv


DROP TABLE IF EXISTS #dnv_informativas_inhabilitada
SELECT
   [sNumDocInvalidaTmp] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   spna.*
   INTO #dnv_informativas_inhabilitada
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
   -- 1 | 30,457
   -- 0 | 395
   spna.bActivo = 0 -- Inhabilitada 
   AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'


SELECT
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [Total] = COUNT(1)
FROM SimPersonaNoAutorizada dnv
LEFT JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
WHERE
   -- 1 | 30,457
   -- 0 | 395
   -- spna.bActivo = 0 -- Inhabilitada 
   stt.sDescripcion = 'ALERTA ES INFORMATIVA'
GROUP BY
   dnv.bActivo

--========================================================================================================================================== */