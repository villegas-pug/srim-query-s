USE SIM
GO

/*░
   → ...
============================================================================================================================================================ */

-- 1: `tmp` ...
DROP TABLE IF EXISTS #tmp_expulsados
SELECT 
   TOP 0
   [nId] = 0,
   sper.sIdDocIdentidad,
   sper.sNumDocIdentidad,
   sper.sIdPaisNacionalidad
   INTO #tmp_expulsados
FROM SimPersona sper

-- 1.1: Bulk...
-- INSERT INTO #tmp_expulsados VALUES()
-- INSERT INTO #tmp_expulsados VALUES(1,'PAS','0028435','ARN')
SELECT COUNT(1) FROM #tmp_expulsados
SELECT * FROM #tmp_expulsados

-- 2: Recuperar `uIdPersona` ...
DROP TABLE IF EXISTS #tmp_expulsados_uId
SELECT 
   e.*,
   [uIdPersona] = (

                     SELECT 
                        TOP 1
                        sdp.uIdPersona
                     FROM SimDocPersona sdp
                     JOIN SimPersona sper ON sdp.uIdPersona = sper.uIdPersona
                     WHERE
                        sdp.bActivo = 1
                        AND sdp.sIdDocumento = e.sIdDocIdentidad
                        AND sdp.sNumero = e.sNumDocIdentidad
                        AND sper.sIdPaisNacionalidad = e.sIdPaisNacionalidad
                     ORDER BY
                        sdp.dFechaHoraAud DESC

                  )
   INTO #tmp_expulsados_uId
FROM #tmp_expulsados e

-- Index ...
CREATE NONCLUSTERED INDEX ix_tmp_expulsados_uId_uIdPersona 
ON #tmp_expulsados_uId(uIdPersona);

-- Test ...
SELECT * FROM #tmp_expulsados_uId e
WHERE e.uIdPersona IS NOT NULL

-- 3: Final: MovMigra ...
DROP TABLE IF EXISTS #tmp_expulsados_uId_final
SELECT 
   e.*,
   [Apellido Paterno(SIM)] = (

                           SELECT 
                              sper.sPaterno
                           FROM SimPersona sper
                           WHERE
                              sper.bActivo = 1
                              AND sper.uIdPersona = e.uIdPersona

                     ),
   [Ultimo MovMigra] = (

                           SELECT 
                              TOP 1 
                              smm.sTipo 
                           FROM SimMovMigra smm
                           WHERE
                              smm.bAnulado = 0
                              AND smm.bTemporal = 0
                              AND smm.uIdPersona = e.uIdPersona
                           ORDER BY
                              smm.dFechaControl DESC   

                     ),
   [Fecha Ultimo MovMigra] = (

                              SELECT 
                                 TOP 1 
                                 smm.dFechaControl
                              FROM SimMovMigra smm
                              WHERE
                                 smm.bAnulado = 0
                                 AND smm.bTemporal = 0
                                 AND smm.uIdPersona = e.uIdPersona
                              ORDER BY
                                 smm.dFechaControl DESC   

                           ),
   [Observaciones] = (

                        SELECT 
                           TOP 1 
                           smm.sObservaciones
                        FROM SimMovMigra smm
                        WHERE
                           smm.bAnulado = 0
                           AND smm.bTemporal = 0
                           AND smm.uIdPersona = e.uIdPersona
                        ORDER BY
                           smm.dFechaControl DESC   

                     ),
   [Dirección Domiciliaria] = (
                                 CASE
                                    WHEN (e.sIdPaisNacionalidad = 'PER' AND e.uIdPersona IS NOT NULL) THEN (
                                       SELECT CONCAT(su.sNombre, '; ', spe.sDomicilio) FROM SimPeruano spe
                                       JOIN SimUbigeo su ON spe.sIdUbigeoDomicilio = su.sIdUbigeo
                                       WHERE
                                          spe.uIdPersona = e.uIdPersona
                                       
                                    )
                                    WHEN (e.sIdPaisNacionalidad != 'PER' AND e.uIdPersona IS NOT NULL) THEN (
                                       SELECT 
                                          CONCAT(su.sNombre, '; ', se.sDomicilio) 
                                       FROM SimExtranjero se
                                       JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
                                       WHERE
                                          se.uIdPersona = e.uIdPersona
                                       
                                    )
                                 END

                              )
   INTO #tmp_expulsados_uId_final
FROM #tmp_expulsados_uId e


-- Test ...
SELECT COUNT(1) FROM #tmp_expulsados e

SELECT e.* FROM #tmp_expulsados_uId_final e

-- 3
SELECT * FROM #tmp_expulsados e
WHERE
   e.nId = 1079

-- 4
SELECT * FROM SimPersona sper
WHERE
   sper.sNombre = 'ALEX MAURICIO'
   AND sper.sPaterno = 'CASTILLO'
   AND sper.sMaterno = 'OSORIO'

-- 5
SELECT * FROM SimDocumento sd 
WHERE 
   sd.sDescripcion LIKE '%dula%'
   -- sd.sIdDocumento LIKE '%CC%'
   


SELECT 
   sdp.*,
   sper.*
FROM SimDocPersona sdp
JOIN SimPersona sper ON sdp.uIdPersona = sper.uIdPersona
WHERE
   -- sdp.sIdDocumento IN ('CPP', 'CTP')
   -- sdp.sIdDocumento IN ('CE', 'CEE')
   -- sdp.sIdDocumento IN ('CEE')
   -- sdp.sIdDocumento IN ('CDN')
   -- sdp.sIdDocumento IN ('PAS')
   sdp.sIdDocumento IN ('CIP')
   AND sdp.sNumero = '19115271'

-- PBA | PAISES BAJOS
USE SIM
GO

SELECT * FROM SimPais sp 
WHERE 
   sp.sNombre LIKE '%YIB%'
   -- sp.sIdPais LIKE '%USA%'
    
-- ============================================================================================================================================================*/

SELECT TOP 10 * FROM [dbo].[SimMovMigraComplementario]
SELECT TOP 10 * FROM [dbo].[SimMovMigra_Migrado]
SELECT COUNT(1) FROM [dbo].[SimMovMigra_Migrado]

SELECT COUNT(1) FROM [dbo].[SimParteDiario]
SELECT COUNT(1) FROM [dbo].[SimDetalleParte]
SELECT TOP 10 * FROM [dbo].[SimDetalleParte]

SELECT TOP 10 * FROM [dbo].[SimDatosPersonalesPDA]
SELECT TOP 10 * FROM [dbo].[SimSistPersonaDatosAdicionalPDA]

EXEC sp_help SimPersona

-- 1,737,121
SELECT COUNT(1) FROM xTotalExtranjerosPeru

SELECT 

   sper.uIdPersona,
   sdp.sIdDocumento,
   [sNumeroDocumento] = CONCAT('''', sdp.sNumero),
   sper.sNombre,
   sper.sPaterno, 
   sper.sMaterno,
   sper.sSexo,
   sper.dFechaNacimiento,
   sper.sIdPaisNacimiento,
   sper.sIdPaisResidencia,
   sper.sIdPaisNacionalidad,
   sper.sIdEstadoCivil
 
FROM SimDocPersona sdp
JOIN SimPersona sper ON sdp.uIdPersona = sper.uIdPersona
WHERE
   sdp.bActivo = 1
   AND sdp.sIdDocumento = 'SLV'
   AND sdp.dFechaHoraAud >= '2022-01-01 00:00:00.000'



[dbo].[SimCitasNacionalidad]