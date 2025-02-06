USE SIM
GO

/*» V1 ... 
=============================================================================================================================================================== */
-- 1.
DROP TABLE IF EXISTS #tmp_simpersona
SELECT p.* INTO #tmp_simpersona FROM (

   SELECT 
      sper.*,
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY
                                       SOUNDEX(sper.sNombre),
                                       sper.sPaterno,
                                       sper.sMaterno,
                                       sper.sSexo,
                                       sper.dFechaNacimiento,
                                       sper.sIdPaisNacimiento
                                       -- sper.sIdPaisResidencia,
                                       -- sper.sIdPaisNacionalidad
                              )
   FROM SimPersona sper
   WHERE
      sper.bActivo = 1
      AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sper.sIdPaisNacimiento = 'PER'

) p
WHERE
   p.nDupl >= 2

-- 2
-- 2.1 Peruanos con carnet de extranjeria ...
DROP TABLE IF EXISTS #tmp_simpersona_con_ce
SELECT p.* INTO #tmp_simpersona_con_ce FROM #tmp_simpersona p
WHERE 
   p.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   AND EXISTS (

      SELECT 1 FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
      WHERE
         e.uIdPersona = p.uIdPersona
         AND e.uIdPersona != '00000000-0000-0000-0000-000000000000'
         -- AND e.CalidadTipo IN ('N', 'R')
         AND e.CalidadTipo IN ('R')

   )

-- 2.2 Peruanos con CCM → `P` ...
DROP TABLE IF EXISTS #tmp_simpersona_con_ccm
SELECT p.* INTO #tmp_simpersona_con_ccm FROM #tmp_simpersona p
WHERE 
   p.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   AND EXISTS (

      SELECT 1 FROM SimTramite st
      JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
      WHERE
         st.bCancelado = 0
         AND st.uIdPersona = p.uIdPersona
         AND st.nIdTipoTramite = 58 -- CCM
         AND sti.sEstadoActual = 'P'

   )


SELECT p.* FROM (
   SELECT
      sper.sIdDocIdentidad,
      sper.sNumDocIdentidad,
      sper.sNombre,
      sper.sPaterno,
      sper.sMaterno,
      sper.sSexo,
      sper.dFechaNacimiento,
      sper.sIdPaisNacimiento,
      sper.sIdPaisNacionalidad,
      [sUltimoMovMigra] = smm.sTipo,
      [dFechaMovMigra] = smm.dFechaControl,
      [nUltMovMig] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
   FROM #tmp_simpersona_con_ce sper
   LEFT JOIN SimMovMigra smm ON sper.uIdPersona = smm.uIdPersona
) p 
WHERE
   p.nUltMovMig = 1

SELECT
   sper.sIdDocIdentidad,
   sper.sNumDocIdentidad,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.sSexo,
   sper.dFechaNacimiento,
   sper.sIdPaisNacimiento,
   sper.sIdPaisNacionalidad
FROM #tmp_simpersona_con_ccm sper

-- =============================================================================================================================================================== */


/*» V2 ... 
=============================================================================================================================================================== */
-- 1.
-- EXEC sp_help SimPersona 
DROP TABLE IF EXISTS #tmp_simpersona
SELECT p.* INTO #tmp_simpersona FROM (

   SELECT 
      sper.*,
      [nDuplPorNacimiento] = COUNT(1) OVER (
                                    PARTITION BY
                                          SOUNDEX(sper.sNombre),
                                          sper.sPaterno,
                                          sper.sMaterno,
                                          sper.sSexo,
                                          sper.dFechaNacimiento,
                                          sper.sIdPaisNacimiento
                                          -- sper.sIdPaisResidencia,
                                          -- sper.sIdPaisNacionalidad
                                 )
   FROM SimPersona sper
   WHERE
      sper.bActivo = 1
      AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sper.sIdPaisNacimiento = 'PER'

) p
/* WHERE
   p.nDupl >= 2 */

-- 2
-- 2.1 Peruanos con carnet de extranjeria ...
DROP TABLE IF EXISTS #tmp_simpersona_con_ce
SELECT p.* INTO #tmp_simpersona_con_ce FROM #tmp_simpersona p
WHERE 
   p.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   AND EXISTS (

      SELECT 1 FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
      WHERE
         e.uIdPersona = p.uIdPersona
         AND e.uIdPersona != '00000000-0000-0000-0000-000000000000'
         -- AND e.CalidadTipo IN ('N', 'R')
         AND e.CalidadTipo IN ('R')

   )

-- 2.2 Peruanos con CCM → `P` ...
DROP TABLE IF EXISTS #tmp_simpersona_con_ccm
SELECT p.* INTO #tmp_simpersona_con_ccm FROM #tmp_simpersona p
WHERE 
   p.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   AND EXISTS (

      SELECT 1 FROM SimTramite st
      JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
      WHERE
         st.bCancelado = 0
         AND st.uIdPersona = p.uIdPersona
         AND st.nIdTipoTramite = 58 -- CCM
         AND sti.sEstadoActual = 'P'

   )


SELECT p.* FROM (
   SELECT
      sper.sIdDocIdentidad,
      sper.sNumDocIdentidad,
      sper.sNombre,
      sper.sPaterno,
      sper.sMaterno,
      sper.sSexo,
      sper.dFechaNacimiento,
      sper.sIdPaisNacimiento,
      sper.sIdPaisNacionalidad,
      [sUltimoMovMigra] = smm.sTipo,
      [dFechaMovMigra] = smm.dFechaControl,
      [nUltMovMig] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
   FROM #tmp_simpersona_con_ce sper
   LEFT JOIN SimMovMigra smm ON sper.uIdPersona = smm.uIdPersona
) p 
WHERE
   p.nUltMovMig = 1

SELECT
   sper.sIdDocIdentidad,
   sper.sNumDocIdentidad,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.sSexo,
   sper.dFechaNacimiento,
   sper.sIdPaisNacimiento,
   sper.sIdPaisNacionalidad
FROM #tmp_simpersona_con_ccm sper

--
-- Vilchez Fernández, Luis Enrique
SELECT sper.* FROM SimPersona sper 
WHERE 
   sper.sNombre = 'Luis Enrique'
   AND sper.sPaterno = 'Vilchez'
   AND sper.sMaterno = 'Fernandez'

-- =============================================================================================================================================================== */


/* 
   3. Consultar SIM.dbo.SimMovMigra por número de vuelo, aerolinea y fecha llegada ...
-- =============================================================================================================================================================== */

SELECT * FROM SimMovMigra smm


SELECT TOP 10 si.* FROM SimItinerario si WHERE
TRY_CONVERT(INT, si.sNumeroNave) = 802 -- lvichez
AND si.nIdTransportista = 60 -- 60 | SKY AIRLINE | lvichez
AND si.dFechaProgramada BETWEEN '20200123' AND '20200123'  -- lvichez



SELECT sd.* FROM SimDependencia sd WHERE sd.sIdDependencia LIKE '27'

-- 60 | SKY AIRLINE
SELECT TOP 10 semp.* FROM SimEmpTransporte semp 
WHERE 
   -- semp.sNombreRazon LIKE '%LA%'
   -- semp.sSigla = 'LA'
   semp.nIdTransportista = 72

EXEC sp_help SImItinerario

-- 1
DROP TABLE IF EXISTS #tmp_simmovmigra_atsg
SELECT 
   smm.dFechaControl,
   smm.sTipo,
   smm.uIdPersona,
   smm.sIdDocumento,
   smm.sNumeroDoc,
   smm.sIdDependencia,
   smm.sNombres,
   smm.sIdPaisNacionalidad,

   si.sIdItinerario,
   si.dFechaProgramada,
   si.sNumeroNave,
   si.nIdTransportista

   INTO #tmp_simmovmigra_atsg
   -- si.*
FROM SimMovMigra smm
JOIN SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.sTipo = 'E'
   AND smm.sIdDependencia = '27' -- 27 | A.I.J.CH.
   -- AND TRY_CONVERT(INT, si.sNumeroNave) = 802 -- lvichez
   AND TRY_CONVERT(INT, si.sNumeroNave) = 263 -- e1
   -- AND TRY_CONVERT(INT, si.sNumeroNave) = 2699 -- e2
   -- AND si.nIdTransportista = 60 -- 60 | SKY AIRLINE | lvichez
   AND si.nIdTransportista = 20 -- 20 | COPA | e1
   -- AND si.nIdTransportista = 72 -- 72 | LATAM | e2
   -- AND smm.dFechaControl BETWEEN '2020-01-23 00:00:00.000' AND '2020-01-23 23:59:59.999' -- lvichez
   -- AND smm.sIdItinerario = '2020AI004938'
   -- AND si.dFechaProgramada = '2020-01-23' -- lvichez
   AND smm.dFechaControl BETWEEN '2023-08-08 00:00:00.000' AND '2023-08-08 23:59:59.999' -- e1
   -- AND smm.dFechaControl BETWEEN '2023-09-04 00:00:00.000' AND '2023-09-04 23:59:59.999' -- e2
   
-- 2. Final ...
SELECT mm.* FROM #tmp_simmovmigra_atsg mm
UNION
SELECT
   smm.dFechaControl,
   smm.sTipo,
   smm.uIdPersona,
   smm.sIdDocumento,
   smm.sNumeroDoc,
   smm.sIdDependencia,
   smm.sNombres,
   smm.sIdPaisNacionalidad,

   si.sIdItinerario,
   si.dFechaProgramada,
   si.sNumeroNave,
   si.nIdTransportista

   -- si.*
FROM SimMovMigra smm
JOIN SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.sTipo = 'E'
   AND smm.sIdDependencia = '27' -- 27 | A.I.J.CH.
   AND smm.sIdItinerario IN (
                                 SELECT mma.sIdItinerario FROM #tmp_simmovmigra_atsg mma 
                                 GROUP BY mma.sIdItinerario
                           )
   AND smm.dFechaControl > '2023-08-08 23:59:59.999'

                                 

-- Buscar itinerario en SimMovMigra
SELECT * FROM SimPersona sper WHERE sper.sNumDocIdentidad = '27041242'
SELECT smm.sIdItinerario, smm.dFechaControl FROM SimMovMigra smm WHERE smm.uIdPersona = '28c8e842-b8bb-4be1-b5c8-88894fb60217'

-- SimMovMigra
SELECT 
   smm.dFechaControl,
   smm.sTipo,
   smm.uIdPersona,
   smm.sIdDocumento,
   smm.sNumeroDoc,
   smm.sIdDependencia,
   smm.sNombres,
   smm.sIdPaisNacionalidad,

   smm.sIdItinerario

   /* si.sNumeroNave,
   si.nIdTransportista */

FROM SimMovMigra smm -- 144
WHERE
   smm.sIdItinerario = '2023AI037287'
   

-- Buscar itinerario por: Número vuelo, fecha vuelo y aerolinea de ATSG ...
SELECT 
   -- COUNT(1)
   smm.dFechaControl,
   smm.sTipo,
   smm.uIdPersona,
   smm.sIdDocumento,
   smm.sNumeroDoc,
   smm.sIdDependencia,
   smm.sNombres,
   smm.sIdPaisNacionalidad
FROM SimMovMigra smm 
WHERE 
   smm.sIdItinerario = (

   SELECT -- ?
      si.sIdItinerario
      /* si.dFechaProgramada,
      si.sNumeroNave,
      si.nIdTransportista */
      -- si.*
   FROM SimItinerario si
   WHERE
      si.sTipoMovimiento = 'E'
      AND si.sIdDependencia = '27' -- 27 | A.I.J.CH.
      AND TRY_CONVERT(INT, si.sNumeroNave) = 263 -- e1
      -- AND si.nIdTransportista = 20 -- 20 | COPA | e1
      AND CAST(si.dFechaProgramada AS DATE) = '2023-08-07' -- e1

)
-- 2023AI037275
-- 2023AI037275
-- 2023AI037134
-- 2023AI037134
SELECT 
   CAST(smm.dFechaControl AS DATE)
FROM SimMovMigra smm
WHERE
   smm.sIdItinerario = '2023AI037134'
GROUP BY
   CAST(smm.dFechaControl AS DATE)

-- Movimiento migratorios por Itienerario ...
EXEC sp_help SimMovMigra
SELECT

   smm.uIdPersona,
   smm.sNombres,
   smm.dFechaControl,
   smm.dFechaDigita,
   [sTipoMov] = smm.sTipo,
   smm.sIdItinerario,
   smm.sIdPaisNacionalidad,
   smm.sIdDocumento,
   smm.sNumeroDoc,
   smm.sIdPaisMov,

   [sDependencia] = sd.sNombre,
   [sOperadorLogin] = su.sLogin,
   [sOperadorDigita] = su.sNombre,
   [sModuloDigita] = sm.sIdModulo,
   [sIdModuloDigita] = sm.sNombre

FROM SimMovMigra smm
JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
JOIN SimUsuario su ON smm.nIdOperadorDigita = su.nIdOperador
JOIN SimModulo sm ON smm.sIdModuloDigita = sm.sIdModulo
WHERE
   smm.sIdItinerario = '2023AI037134'


-- =============================================================================================================================================================== */