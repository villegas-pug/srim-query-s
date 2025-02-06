USE SIM
GO

-- 1
EXEC sp_help SimPersona
DROP TABLE IF EXISTS RimMovMigra
CREATE TABLE [dbo].[RimMovMigra](

   -- Control migratorio
	[sIdMovMigratorio] [char](14) NOT NULL,
	[dFechaControl] [datetime] NOT NULL,
	[sTipo] [char](1) NOT NULL,
	[uIdPersona] [uniqueidentifier] NOT NULL,
	[sIdDocumento] [char](3) NOT NULL,
	[sNumeroDoc] [varchar](25) NOT NULL,
	[sIdDependencia] [char](3) NOT NULL,
	[sIdPaisNacionalidad_ISO3] [char](3) NULL,

   -- Persona
	[sNombre] [varchar](60) NOT NULL,
	[sApellidos] [varchar](100) NOT NULL,
	[sSexo] [char](1) NOT NULL,
	[dFechaNacimiento] [datetime] NULL,

)

-- 3
SELECT 
   
   -- Control migratorio
	smm.sIdMovMigratorio,
	smm.dFechaControl,
	smm.sTipo,
	[sIdPaisNacionalidad_ISO3] = sp.sCodigoIso,
	smm.uIdPersona,
	smm.sIdDocumento,
	smm.sNumeroDoc,
	smm.sIdDependencia,
	si.sNumeroNave,

   -- Persona
	sper.sNombre,
	[sApellidos] = CONCAT(sper.sPaterno, ' ', sper.sMaterno),
	sper.sSexo,
	sper.dFechaNacimiento
   
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
JOIN SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
WHERE
   smm.bAnulado = 0
	AND smm.bTemporal = 0
   AND smm.sTipo = 'E'
	-- AND smm.sIdPaisMov != 'PER'
   AND smm.dFechaControl BETWEEN '2022-08-08 00:00:00.000' AND '2022-08-08 23:59:59.999'


-- 40,700
EXEC sp_help SimMovMigra
SELECT COUNT(1) FROM SimMovMigra


SELECT * FROM SimDocPersona sdp 
WHERE sdp.sIdDocumento = 'PAS' AND sdp.sNumero = '18FA26768'

SELECT * FROM SimMovMigra smm 
WHERE 
	/* smm.sIdDocumento = 'PAS' 
	AND smm.sNumeroDoc = '18FA26768' */
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona IN (
		'db8ddbc9-098e-40bb-8758-b1fea69f767d',
		'd7179cfa-ad2d-4161-a415-b8021be92518'
	)
ORDER BY smm.dFechaControl DESC



-- Test ...

-- 1
-- cfe99249-a505-4230-99fb-8a5cb217c824
SELECT sper.* FROM SimPersona sper
WHERE 
	sper.sNombre = 'JANINA'
	AND sper.sPaterno = 'SCHMID'

SELECT 
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdPaisMov
FROM SimMovMigra smm
WHERE smm.uIdPersona = 'cfe99249-a505-4230-99fb-8a5cb217c824'
ORDER BY
	smm.dFechaControl DESC

-- 2
SELECT sdp.*, sper.* FROM SimDocPersona sdp
JOIN SimPersona sper ON sdp.uIdPersona = sper.uIdPersona
WHERE
	sdp.sIdDocumento = 'PAS'
	AND sdp.sNumero = '107190722'


SELECT * FROM SIM.dbo.SimPais sp WHERE sp.sNombre LIKE 'para%'
SELECT * FROM SIM.dbo.SimPais sp WHERE sp.bActivo = 1

-- SELECT FORMAT(8004, 000000)

EXEC sp_help SimItinerario
SELECT TOP 10 * FROM SimItinerario si WHERE si.sIdItinerario LIKE '2023%8004'

SELECT TOP 10 * FROM SimItinerario si 
WHERE 
	-- RIGHT(si.sNumeroNave, 6) = FORMAT(8004, '000000')
	LEFT(si.sIdItinerario, 4) = 2022
	AND RIGHT(si.sNumeroNave, 6) = FORMAT(8004, '000000')

SELECT TOP 10 * FROM SIM.dbo.SimMovMigraMod
SELECT TOP 10 * FROM SIM.dbo.SimItinerario si
ORDER BY si.dFechaProgramada DESC

SELECT
	sp.nIdContinente,
	sp.dFechaHoraAud,
	-- [nFila] = ROW_NUMBER() OVER(ORDER BY sp.dFechaHoraAud),
	[nAñoAud] = DATEPART(YYYY, sp.dFechaHoraAud),
	/* [nTotal] = SUM(CAST(sp.bActivo AS FLOAT)) OVER (PARTITION BY YEAR(sp.dFechaHoraAud) 
												               ORDER BY sp.dFechaHoraAud 
																	ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) */
	[nAcc] = SUM(sp.nIdContinente) OVER (PARTITION BY YEAR(sp.dFechaHoraAud) 
												             ORDER BY sp.dFechaHoraAud)
	/* [nTotal] = SUM(CAST(sp.bActivo AS FLOAT)) OVER (PARTITION BY YEAR(sp.dFechaHoraAud) 
																   ORDER BY sp.dFechaHoraAud) */
FROM SimPais sp
WHERE
	sp.bActivo = 1
	-- AND sp.dFechaHoraAud <= '2006-08-30 20:26:33.780'

EXEC sp_help SimItinerario
SELECT TOP 10 * FROM SimPais sp


-- 1. Buscar en Movimiento Migratorio ...

SELECT -- Atributos
   -- Control migratorio
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdDocumento,
	smm.sNumeroDoc,
	smm.sIdDependencia,

	-- Itienerario
	si.sIdItinerario,
	si.sNumeroNave,
	[dFechaProgItinerario] = si.dFechaProgramada,
	[sEmpresaTransporte] = semp.sNombreRazon,

   -- Persona
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
LEFT JOIN SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
LEFT JOIN SimEmpTransporte semp ON si.nIdTransportista = semp.nIdTransportista
WHERE
   smm.bAnulado = 0
	AND smm.bTemporal = 0
   AND smm.sTipo = 'E'
	AND smm.sIdDependencia = '27'

	-- 2
	/* AND sper.sNombre LIKE '%MARITZA%'
	AND sper.sPaterno = 'MONGE'
	AND sper.sMaterno = 'DEL VALLE' */

	AND TRY_CONVERT(INT, si.sNumeroNave) = 263
	AND smm.dFechaControl BETWEEN '2023-08-07 00:00:00.000' AND '2023-08-07 23:59:59.999'
	-- AND smm.sIdDocumento = 'PAS'
	-- AND smm.sNumeroDoc = '596737400' -- # de nave de itinerarion distinto número vuelo de atsg, todo lo demás es igual ...

ORDER BY 
	smm.dFechaControl DESC



-- SimMovMigra
SELECT sper.* FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE 
	sper.sNombre LIKE '%MARITZA%'
	AND sper.sPaterno = 'MONGE'
	AND sper.sMaterno LIKE '%DEL%'


-- 31 | LAN CHILE | LA
SELECT * FROM SimEmpTransporte stra WHERE stra.sNombreRazon LIKE '%LA%'

-- 183 | VOLARIS → No registras vuelos en `ATSG` ...
EXEC sp_help SimItinerario


SELECT * FROM SimDocPersona  sdp
WHERE sdp.sNumero = '120296288'

/* SELECT COUNT(1) FROM SimMovMigra smm 
WHERE 
	AND smm.s
	smm.sIdDependencia = '27'
	AND smm.sIdItinerario IS NULL */