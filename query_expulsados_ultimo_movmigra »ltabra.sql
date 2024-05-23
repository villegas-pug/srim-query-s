USE SIM
GO

/*░
   →
============================================================================================================================================================*/

-- 1: `tmp` ...
DROP TABLE IF EXISTS #tmp_expulsados
SELECT 
   TOP 0
   [nId] = 0,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.dFechaNacimiento,
   [sNacionalidad] = sper.sObservaciones
   INTO #tmp_expulsados
FROM SimPersona sper

-- 1.1: Bulk...
-- INSERT INTO #tmp_expulsados VALUES()

-- 2: Recuperar `uIdPersona` ...
DROP TABLE IF EXISTS #tmp_expulsados_uId
SELECT 
   e.*,
   [uIdPersona] = (

                     SELECT 
                        TOP 1 sper.uIdPersona 
                     FROM SimPersona sper
                     JOIN SimPais sp ON sper.sIdPaisNacionalidad = sp.sIdPais
                     WHERE
                        sper.bActivo = 1
                        AND sper.sNombre = e.sNombre
                        AND sper.sPaterno = e.sPaterno
                        AND sper.sMaterno = e.sMaterno
                        AND sper.dFechaNacimiento = e.dFechaNacimiento
                        AND sp.sNacionalidad = e.sNacionalidad
                     ORDER BY
                        sper.dFechaHoraAud DESC   

                  )
   INTO #tmp_expulsados_uId
FROM #tmp_expulsados e

-- Test ...
SELECT * FROM #tmp_expulsados_uId e
WHERE e.uIdPersona IS NOT NULL

-- 3: Final: MovMigra ...

SELECT 
   e.*,
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
   [SObservaciones] = (

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

                     )
FROM #tmp_expulsados_uId e



-- Test ...
SELECT COUNT(1) FROM #tmp_expulsados e


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


SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%bajo%'

-- ============================================================================================================================================================*/

