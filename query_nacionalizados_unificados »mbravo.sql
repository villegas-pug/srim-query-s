USE SIM
GO

CREATE INDEX IX_SimUnionAuditoria_uIdPersonaP
    ON dbo.SimUnionAuditoria(uIdPersonaP)

SELECT TOP 100 * FROM SimTituloNacionalidad stn
ORDER BY stn.dFechaEmision DESC

SELECT
	stn.sNumeroTitulo,
	[uIdPersona_Ext] = stn.uIdPersona,
	[uIdPersona_Per] = stn.uIdPersonaNac,
	[dFechaTitulo] = stn.dFechaEmision,
	stn.sIdPaisNacimiento,
	spere.sNombre,
	spere.sPaterno,
	spere.sMaterno,
	spere.sNombre,
	spere.sSexo,
	spere.dFechaNacimiento,
	spere.sIdPaisNacionalidad,
	[bUnificado_uIdPersonaExt] = (
									IIF(
										EXISTS(
											SELECT TOP 1 1 FROM SimUnionAuditoria sua
											WHERE
												-- sua.uIdPersonaP = stn.uIdPersonaNac -- uId → Peruano ...
												sua.uIdPersonaP = stn.uIdPersona -- uId → Extranjero ...
												AND sua.sTablaEval = 'SIMMOVMIGRA' -- sTablaEval: SIMMOVMIGRA
										),
										'Si',
										'No'
									)
								)
FROM SimTituloNacionalidad stn
JOIN SimPersona spere ON stn.uIdPersona = spere.uIdPersona


-- Test ...
SELECT TOP 100 * FROM SimUnionAuditoria

/*
	P → 676590A9-9897-4014-B3F1-9CF2BC35DA53	
	S → 993586E5-C3CC-4F8C-84B6-4F8196EC7D14	
	Tabla → SIMMOVMIGRA	
	Campo → sIdMovMigratorio
	Valor → 2001AI00367555
*/

SELECT si.xImagen, sie.xImagen, sper.*, smm.* FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
LEFT JOIN SimimagenExtranjero sie ON sper.uIdPersona = sie.uIdPersona
LEFT JOIN SimImagen si ON sper.uIdPersona = si.uIdPersona
WHERE
	-- smm.sIdMovMigratorio = '2001AI00367555'
	smm.sIdDocumento = 'CIP'
	AND smm.sNumeroDoc = '108555403'


SELECT sie.xImagen, sper.*, smm.* FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
LEFT JOIN SimimagenExtranjero sie ON sper.uIdPersona = sie.uIdPersona
-- LEFT JOIN SimImagen si ON sper.uIdPersona = si.uIdPersona
WHERE
	-- smm.sIdMovMigratorio = '2001AI00367555'
	-- smm.sIdDocumento = 'CIP'
	-- AND smm.sNumeroDoc = '108555403'
	smm.sNumeroDoc = '517251050'


SELECT * FROM SimUnionAuditoria sua
WHERE
	sua.uIdPersonaP = '676590A9-9897-4014-B3F1-9CF2BC35DA53'
	AND sua.sValorCampos = '2001AI00367555'



SELECT TOP 10 * FROM SimimagenExtranjero  sie
WHERE
	sie.uIdPersona = 'A556BFF0-FD9B-41AC-8268-CC88FBE01913'

SELECT 
	sm.sIdModulo,
	sm.sNombre,
	si.* 
FROM SimImagen si
LEFT JOIN SimSesion ss ON si.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
-- JOIN SimTipoImagen sti ON si.nIdTipoImagen = sti.nIdTipoImagen
WHERE
	si.uIdPersona = 'A556BFF0-FD9B-41AC-8268-CC88FBE01913'
ORDER BY
	si.dFechaHoraAud DESC


-- A556BFF0-FD9B-41AC-8268-CC88FBE01913
SELECT TOP 10 * FROM SimSimMovMigra sper

-- PER
SELECT TOP 10 * FROM SimPersona sper
WHERE
	sper.sIdDocIdentidad = 'DNI'
	AND sper.sNumDocIdentidad = '45878442'

-- PAS
-- A556BFF0-FD9B-41AC-8268-CC88FBE01913
SELECT st.uIdPersona, spas.* FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
WHERE
	spas.sPasNumero = '122394785'



SELECT TOP 10 * FROM [dbo].[SimPreeImagen]
SELECT TOP 10 * FROM [dbo].[SimAgregado]
