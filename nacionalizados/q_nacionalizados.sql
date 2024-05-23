-- ========================================================================================================================================

-- ░ Nacionalizados 
-- ========================================================================================================================================
USE SIM
GO

SELECT
	se.nIdEtapa,
	[nSecuencia] = sett.nSecuencia,
	[sEtapa] = se.sDescripcion
FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE sett.nIdTipoTramite = 78 -- 69, 71, 72, 73, 76, 78, 79
ORDER BY
	sett.nSecuencia

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimNacionalizados
SELECT * INTO BD_SIRIM.dbo.RimNacionalizados FROM
(
	SELECT
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Impresión] = (
								SELECT TOP 1 setn.dFechaHoraAud FROM SimEtapaTramiteNac setn 
								WHERE 
									setn.sNumeroTramite = st.sNumeroTramite
									AND setn.nIdEtapa = 6 -- 6 | IMPRESION
									-- AND setn.sEstado = 'F'
								ORDER BY
									setn.dFechaHoraAud DESC
							),
		[Tipo Trámite] = stt.sDescripcion,
		[Dependencia] = sd.sNombre,
		[Sexo] = sp.sSexo,
		[Fec Nacimiento] = sp.dFechaNacimiento,
		[Id Nacionalidad] = spa.sIdPais,
		[Nacionalidad] = spa.sNacionalidad,
		[Domicilio] = su.sNombre,
		[Dirección Domiciliaria] = se.sDomicilio
	FROM SimTramite st
	JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
	JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	LEFT JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	LEFT JOIN SimExtranjero se ON st.uIdPersona = se.uIdPersona
	LEFT JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
	LEFT JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		st.bCancelado = 0
		AND stn.nIdEtapaActual IN (6, 48, 40, 47, 42, 53, 43, 44)
		AND (
				SELECT TOP 1 YEAR(setn.dFechaHoraAud) FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
				ORDER BY
					setn.dFechaHoraAud DESC
			) >= 2016
		AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
		-- AND stn.sEstadoActual = 'A'
) tmp_nac
ORDER BY
	tmp_nac.[Fecha Impresión]

-- Test ...
SELECT * FROM BD_SIRIM.dbo.RimNacionalizados