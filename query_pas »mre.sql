USE BD_SIRIM
GO

-- Base Central de PAS
SELECT TOP 10 * FROM RimPasaporte p
WHERE
	p.sNumeroPasaporte LIKE '[2]%'

-- SimPasaporte
SELECT 
	TOP 1000
	sp.sPasNumero,
	[sTipoTramite] = stt.sDescripcion,
	sp.*
FROM SIM.dbo.SimPasaporte sp
JOIN SIM.dbo.SimTramite st ON sp.sNumeroTramite = st.sNumeroTramite
JOIN Sim.dbo.SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	/*sp.sPasNumero LIKE '[2]%'
	AND LEN(sp.sPasNumero) = 8*/
	st.uIdPersona = '95B3B92D-E966-45AF-938A-1635F752DBB8'
ORDER BY
	sp.dFechaEmision DESC


-- SimMovMigra: DIPLOMÁTICO PASAPORTE ESPECIAL
SELECT 
	smm.*
FROM SIM.dbo.SimMovMigra smm
WHERE
	smm.uIdPersona = '95B3B92D-E966-45AF-938A-1635F752DBB8'
	-- AND smm.sNumeroDoc LIKE '[2]%'
ORDER BY
	smm.dFechaControl DESC

-- SimMovMigra: MILITAR PASAPORTE ESPECIAL
SELECT 
	TOP 100
	[sProfesion] = sprof.sDescripcion,
	smm.*
FROM SIM.dbo.SimMovMigra smm
JOIN SIM.dbo.SimProfesion sprof ON smm.sIdProfesion = sprof.sIdProfesion
WHERE
	smm.sNumeroDoc LIKE '[E][0-9]%'
	AND smm.sIdPaisNacionalidad = 'PER'
ORDER BY
	smm.dFechaControl DESC

-- SimMovMigra: OTROS PASAPORTE ESPECIAL
SELECT 
	TOP 100
	[sProfesion] = sprof.sDescripcion,
	smm.*
FROM SIM.dbo.SimMovMigra smm
JOIN SIM.dbo.SimProfesion sprof ON smm.sIdProfesion = sprof.sIdProfesion
WHERE
	smm.sIdPaisNacionalidad = 'PER'
	AND smm.sNumeroDoc LIKE '[a-zA-Z][0-9]%'
	AND smm.sNumeroDoc NOT LIKE '[DE]'
ORDER BY
	smm.dFechaControl DESC