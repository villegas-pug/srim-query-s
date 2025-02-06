USE SIM
GO

-- 1. `tmp`
DROP TABLE IF EXISTS #tmp_docextranjeria
SELECT 
   TOP 0
   nId = REPLICATE(0, 5),
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno
   INTO #tmp_docextranjeria
FROM SimPersona sper

-- 2. Insert ...
-- INSERT INTO #tmp_docextranjeria VALUES()

-- 3
-- 3.1 ...
-- v1: Registros identicos
DROP TABLE IF EXISTS #tmp_docextranjeria_uid
SELECT 
   d.nId, 
   sper.*
   INTO #tmp_docextranjeria_uid
FROM SimPersona sper
RIGHT JOIN #tmp_docextranjeria d ON sper.sNombre = d.sNombre
                                    AND sper.sPaterno = d.sPaterno
                                    AND sper.sMaterno = d.sMaterno
                                    AND sper.bActivo = 1
                                    AND sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN')

-- v2: SOUNDEX
DROP TABLE IF EXISTS #tmp_docextranjeria_uid
SELECT 
   d.nId, 
   sper.*
   INTO #tmp_docextranjeria_uid
FROM SimPersona sper
RIGHT JOIN #tmp_docextranjeria d ON SOUNDEX(sper.sNombre) = SOUNDEX(d.sNombre)
                                    AND SOUNDEX(sper.sPaterno) = SOUNDEX(d.sPaterno)
                                    AND sper.sMaterno = d.sMaterno
                                    AND sper.bActivo = 1
                                    AND sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN')


-- 4. ...
/*
SELECT TOP 10 sptp.*  FROM SimCarnetPTP sptp
ORDER BY sptp.dFechaEmision DESC

SELECT TOP 10 sce.*  FROM SimCarnetExtranjeria sce
ORDER BY sce.dFechaEmision DESC
*/
SELECT 
   d.nId,
   d.uIdPersona,
   [Carné de Permiso Temporal de Permanencia – CPP] = (
                                                            SELECT 
                                                               TOP 1
                                                               [sNumeroCarnet] = CONCAT('''', sptp.sNumeroCarnet)
                                                            FROM SimCarnetPTP sptp
                                                            JOIN SImTramite st ON sptp.sNumeroTramite = st.sNumeroTramite
                                                            WHERE
                                                               sptp.bAnulado = 0
                                                               AND sptp.bEntregado = 1
                                                               AND st.uIdPersona = d.uIdPersona
                                                            ORDER BY sptp.dFechaEmision DESC

                                                         ),
   [Carné de Extranjería / Cédula] = (
                                          SELECT 
                                             TOP 1
                                             [sNumeroCarnet] = CONCAT('''', sce.sNumeroCarnet)
                                          FROM SimCarnetExtranjeria sce
                                          JOIN SImTramite st ON sce.sNumeroTramite = st.sNumeroTramite
                                          WHERE
                                             sce.bAnulado = 0
                                             AND sce.bEntregado = 1
                                             AND st.uIdPersona = d.uIdPersona
                                          ORDER BY sce.dFechaEmision DESC

                                    ),
   [N° Pasaporte] = (
                        SELECT 
                           TOP 1 
                           [sPasNumero] = CONCAT('''', spas.sPasNumero)
                        FROM SimPasaporte spas
                        JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
                        WHERE
                           st.bCancelado = 0
                           AND spas.sEstadoActual = 'E'
                           AND st.uIdPersona = d.uIdPersona
                        ORDER BY
                           spas.dFechaEmision DESC
   ),
   [sObservaciones] = CONCAT('Nacionalidad: ', spn.sNacionalidad, '; Fecha Nacimiento: ', CONVERT(VARCHAR, d.dFechaNacimiento, 105), '; Sexo: ', d.sSexo)
FROM #tmp_docextranjeria_uid d
LEFT JOIN SimPais spn ON d.sIdPaisNacionalidad = spn.sIdPais

-- Test ...
SELECT COUNT(1) FROM #tmp_docextranjeria_uid
SELECT sd.* FROM SimDocumento sd WHERE sd.sIdDocumento = 'CIP'

-- 57
-- 2ed32536-3418-4bb2-b57f-1b883eec9234
-- fb01a89a-aa23-496c-b233-de4ac2905bc2

-- CPP
SELECT 
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sptp.*
FROM SimCarnetPTP sptp
JOIN SImTramite st ON sptp.sNumeroTramite = st.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE
   sptp.bAnulado = 0
   AND sptp.bEntregado = 1
   AND st.uIdPersona = '82cc7989-6425-49be-a7bc-8f958a2c5da6'

-- CE
SELECT 
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sptp.*
FROM SimCarnetExtranjeria sptp
JOIN SImTramite st ON sptp.sNumeroTramite = st.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE
   sptp.bAnulado = 0
   AND sptp.bEntregado = 1
   AND st.uIdPersona = '6c836e09-6fe6-44d1-8b98-e2bfbf17f747'


SELECT COUNT(1) FROM #tmp_docextranjeria

SELECT sper.uIdPersona FROM SimPersona sper 
WHERE
   sper.sNombre = 'Miguel Angel'
   AND sper.sPaterno = 'Molina'
   AND sper.sMaterno = 'Rodriguez'


DROP TABLE IF EXISTS #tmp_uid
SELECT TOP 0 sper.uIdPersona INTO #tmp_uid FROM SimPersona sper

-- INSERT INTO #tmp_uid VALUES()
SELECT 
   u.uIdPersona,
   [sDocumentos] = (
      SELECT sdp.sIdDocumento, sdp.sNumero FROM SimDocPersona sdp
      WHERE
         sdp.bActivo = 1
         AND sdp.uIdPersona = u.uIdPersona
      FOR XML PATH('')
   )
FROM #tmp_uid u






