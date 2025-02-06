USE SIM
GO

-- 1
-- 5618ee87-35c8-4817-b527-6ed56fac1e9d | BIDEN JOSEPH ROBINETTE
SELECT 
   mm.*
FROM SimMovMigra mm
WHERE
   mm.sIdDependencia = '119'
   -- AND mm.uIdPersona = '5618ee87-35c8-4817-b527-6ed56fac1e9d'
   AND mm.uIdPersona = 'cc9c4979-9d21-4fca-a2ba-2f319b507d5f'
GROUP BY
mm.sIdItinerario
ORDER BY mm.dFechaControl DESC

-- Test
-- 119 | PCM GRUPO AEREO 8
SELECT * 
FROM SimDependencia d
WHERE d.sIdDependencia = '119'

SELECT * 
FROM SimPersona pe
WHERE 
   -- pe.sNombre = 'Joe'
   pe.sPaterno = 'Biden'

SELECT * 
FROM SimMovMigra mm
WHERE mm.uIdPersona = 'cc9c4979-9d21-4fca-a2ba-2f319b507d5f'

SELECT 
   TOP 10 * 
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE
   c.TABLE_CATALOG = 'SIM'
   AND c.COLUMN_NAME LIKE '%preImpre%'

-- Doc persona
SELECT *
FROM SimDocPersona dp
WHERE dp.sNumero = '003649142'


-- Cod. Verf: 521693
SELECT TOP 10 * FROM SimCarnetExtranjeria c

SELECT

   TOP 10
   c.*,
   pe.sNombre,
   pe.sPaterno,
   pe.sMaterno,
   pe.sIdPaisNacionalidad

FROM SimCarnetExtranjeria c
JOIN SimPersona pe ON c.uIdPersona = pe.uIdPersona
WHERE 
   c.sNumeroCarnet = '000577602'
   -- c.sNumeroCarnet = '003649142'
   -- c.sNumPreImpreso = '00521693'
   -- c.sNumPreImpreso = '00141501'

SELECT TOP 10 * FROM SimMotivoActualizacionCE


SELECT * 
FROM SimMovMigra mm
WHERE 
   mm.uIdPersona = 'edd5cd32-d573-4a08-9d57-bb709c1eb9e9'


SELECT * 
FROM SimTramite t
WHERE t.uIdPersona = 'edd5cd32-d573-4a08-9d57-bb709c1eb9e9'

SELECT TOP 100 ce.sNumeroCarnet, ce.dFechaEmision
FROM SimCarnetExtranjeria ce
ORDER BY 
   ce.dFechaEmision DESC, ce.sNumeroCarnet DESC

SELECT 
   TOP 100 
   ce.sNumeroCarnet, 
   ce.dFechaEmision,
   ce.sNumPreImpreso
FROM SimCarnetExtranjeria ce
WHERE ce.sNumPreImpreso IS NOT NULL
ORDER BY 
   ce.dFechaEmision ASC


SELECT * 
FROM SimDocPersona d
WHERE 
   -- d.sNumero = '0102245115'
   d.uIdPersona = '89041468-1dc0-4444-8aaf-23ed29c7cce5'