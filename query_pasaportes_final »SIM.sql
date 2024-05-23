USE SIM
GO

-- SIM
SELECT
   [nTotalPasaportes] = pas2.nContar,
   [nPersonas] = COUNT(1)
FROM (

   SELECT
      t.uIdPersona,
      [nContar] = COUNT(1)
   FROM SimTramitePas tp 
   JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND t.nIdTipoTramite = 90 -- PAS-E
   GROUP BY
      t.uIdPersona

) pas2
GROUP BY
   pas2.nContar
ORDER BY
   1 ASC


-- Base Central
SELECT
   [nTotalPasaportes] = pas2.nContar,
   [nPersonas] = COUNT(1)
FROM (

   SELECT
      -- TOP 10
      t.uIdPersona,
      [nContar] = COUNT(1)
   FROM BD_SIRIM.dbo.RimPasaporte pas
   JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
      -- AND t.nIdTipoTramite = 90 --90 ↔ Expedición de Pasaporte Electrónico
      -- AND t.nIdTipoTramite IN (2, 4, 90) -- 2 ↔ EXPEDICION DE PASAPORTE; 4 ↔ ANULACION DE PASAPORTE; 90 ↔ Expedición de Pasaporte Electrónico
   GROUP BY
      t.uIdPersona

) pas2
GROUP BY
   pas2.nContar
ORDER BY
   2 DESC


-- Total personas
-- 3,436,318
SELECT
   [nContar] = COUNT(DISTINCT t.uIdPersona)
FROM BD_SIRIM.dbo.RimPasaporte pas
JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   -- AND t.nIdTipoTramite = 90 --90 ↔ Expedición de Pasaporte Electrónico







-- test 
-- 1
SELECT * 
FROM SimTipoTramite tt
WHERE tt.sDescripcion LIKE '%Pasaporte%'

-- 2
-- b6f5f143-eb0c-4b39-a940-01f54a3b1aaa
SELECT
   pas.*
FROM SimPasaporte pas
JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
WHERE
   t.uIdPersona = 'b6f5f143-eb0c-4b39-a940-01f54a3b1aaa'

-- 3
SELECT
   -- TOP 10
   t.nIdTipoTramite,
   tt.sDescripcion,
   [nContar] = COUNT(1)
FROM SimPasaporte pas
JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
GROUP BY
   t.nIdTipoTramite,
   tt.sDescripcion
ORDER BY 3 DESC

-- 4. Base Central de Pasaporte
-- JAIR EDUARDO TASAYCO ZUÑIGA
SELECT 
   pas.sNumeroPasaporte,
   pas.sNumeroTramite,
   pas.sEstado 
FROM BD_SIRIM.dbo.RimPasaporte pas
WHERE 
   pas.sNombre = 'JAIR EDUARDO'
   AND pas.sApePat = 'TASAYCO'
   AND pas.sApeMat = 'ZUÑIGA'

-- 4.1 SIM
SELECT
   t.uIdPersona,
   pas.sPasNumero,
   pas.sNumeroTramite,
   tt.sDescripcion,
   pas.sEstadoActual
FROM SimPasaporte pas
JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona = '8ad0b2b3-8354-4024-a8c2-20587446d087'
   /* AND t.sNumeroTramite IN (
                              'AI170008475',
                              'AI170020893',
                              'AI170034659',
                              'AI170039422',
                              'AI170046993',
                              'AI180021268',
                              'LM160229641',
                              'AI210003921',
                              'LM170011711'
   ) */


