USE SIM
GO


-- 1: ...
SELECT 
	sev.sNumeroTramite,
	sev.uIdPersona,
	sev.sTipoDoc,
	sev.sNumDoc,
	sev.dFechaDoc,
	sev.sMotivo,
	[sTipoTramite] = stt.sDescripcion,
	[bBiometrico] = (
						CASE
							WHEN EXISTS (SELECT TOP 1 1 FROM SimImagen si 
										 WHERE si.uIdPersona = st.uIdPersona) THEN 'Si'
							WHEN EXISTS (SELECT TOP 1 1 FROM SimImagenExtranjero sie
										 WHERE sie.uIdPersona = st.uIdPersona) THEN 'Si'
							ELSE 'No'
						END
					)
FROM SimTramite st
-- JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimExoPagTramVulner sev ON st.sNumeroTramite = sev.sNumeroTramite
JOIN SimExoPagTramVulnerDocumento sevd ON sev.nIdExoPagTramVuln = sevd.nIdExoPagTramVuln
JOIN SimExoPagTipoTramVuln sttv ON sev.nIdTipoTramite = sttv.nIdTipoTramite
-- JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
-- JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
WHERE
	st.bCancelado = 0
	AND sev.bActivo = 1
	AND sti.sEstadoActual = 'A'


--
SELECT * FROM SimImagenExtranjero sie WHERE sie.uIdPersona = '57697CC2-FFF5-4BAC-BB66-14A59E85A37C'
SELECT TOP 10 * FROM SimImagenExtranjero 

SELECT 
	[sTipoTramite] = stt.sDescripcion,
	sttv.* 
FROM [dbo].[SimExoPagTipoTramVuln] sttv
JOIN SimTipoTramite stt ON sttv.nIdTipoTramite = stt.nIdTipoTramite

SELECT TOP 10 * FROM [dbo].[SimExoPagTramVulnerDocumento]
SELECT TOP 10 * FROM [dbo].[SimExoPagTramVulner] sev
ORDER BY
	sev.dFechaHoraAud DESC

SELECT * FROM SimCalidadMigratoria scm
WHERE
	scm.nIdCalidad IN (318, 317)



SELECT * FROM SimTipoTramite stt 
ORDER BY
	CASE
		WHEN stt.sDescripcion IN ('<NO DEFINIDO>', 'VERIFICACION DE DATOS') THEN 0
		ELSE 1
	END
,
stt.sDescripcion




SELECT 
	smm.uIdPersona,
	[sIdPaisNacionalidad_CM] = smm.sIdPaisNacionalidad,
	[sIdPaisNacionalidad_P] = sper.sIdPaisNacionalidad
FROM SimMovMigra smm 
-- LEFT JOIN SimDocPersona sdp ON smm.sNumeroDoc = sdp.sNumero
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
	-- smm.uIdPersona = '81FFD2D7-0B9F-4905-9323-444E00969AA6'
	-- smm.sIdDocumento = 'DNI'
	-- AND smm.sNumeroDoc LIKE '%[a-zA-Z]%'
	sper.bActivo = 1
	AND sper.sIdPaisNacionalidad = 'PER'
	AND smm.bTemporal = 0
	AND (smm.sIdPaisNacionalidad IN ('NNN', '') OR smm.sIdPaisNacionalidad IS NULL)
ORDER BY 
	-- smm.uIdPersona
	smm.dFechaControl DESC

SELECT TOP 10 * FROM SimDocPersona sdp
SELECT COUNT(1) FROM SimDocPersona sdp

SELECT * FROM SimModulo smm WHERE smm.sIdModulo = 'SIM-AMM'