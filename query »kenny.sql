USE SIM
GO

-- 1: Movmimientos migratorio de peruanos ...

-- 1.1: ...
DROP TABLE IF EXISTS #tmp_mm_per 
SELECT 
	* 
	INTO #tmp_mm_per 
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.dFechaControl >= '2010-01-01 00:00:00.000'
	AND smm.sIdPaisNacimiento IS NOT NULL
	AND smm.sIdPaisNacimiento NOT IN ('PER', 'NNN')
	AND smm.sIdPaisNacionalidad IS NOT NULL
	AND smm.sIdPaisNacionalidad != 'NNN'

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_mm_per_uIdPersona
    ON dbo.#tmp_mm_per(uIdPersona)

-- 1.2: uId distinct de movimientos migratorios de PER ...
DROP TABLE IF EXISTS #tmp_uId_mm_per
SELECT DISTINCT mm_p.uIdPersona INTO #tmp_uId_mm_per FROM #tmp_mm_per mm_p

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_uId_mm_per_uIdPersona
	ON dbo.#tmp_uId_mm_per(uIdPersona)

-- 2: ...
DROP TABLE IF EXISTS #tmp_uId_mm_ext_nacper
SELECT uid_mm_nac.uIdPersona INTO #tmp_uId_mm_ext_nacper FROM (

	SELECT 
		uid_mm.uIdPersona,
		[nNacionalidad(PER)] = (
									IIF(
											EXISTS(SELECT TOP 1 1 FROM #tmp_mm_per mm
													WHERE 
														mm.uIdPersona = uid_mm.uIdPersona
														AND mm.sIdPaisNacionalidad = 'PER'
													),
											1,
											0
										)
		),
		[nNacionalidad(EXT)] = (
									IIF(
											EXISTS(SELECT TOP 1 1 FROM #tmp_mm_per mm
													WHERE 
														mm.uIdPersona = uid_mm.uIdPersona
														AND mm.sIdPaisNacionalidad != 'PER'
													),
											1,
											0
										)
		)
	FROM #tmp_uId_mm_per uid_mm

) uid_mm_nac
WHERE
	uid_mm_nac.[nNacionalidad(PER)] = 1
	AND uid_mm_nac.[nNacionalidad(EXT)] = 1

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_uId_mm_per_mas1nac_uIdPersona
    ON dbo.#tmp_uId_mm_per_mas1nac(uIdPersona)

-- 3: Final ...

-- 3.1: ...
DROP TABLE IF EXISTS #tmp_final
SELECT 
	mm.*,
	sper.sPaterno,
	sper.sMaterno,
	sper.sNombre,
	sper.sSexo,
	sper.dFechaNacimiento,
	[sNumeroTramite] = (
								SELECT TOP 1 st.sNumeroTramite FROM SimTramite st 
								JOIN SimNacionalizacion snac ON st.sNumeroTramite = snac.sNumeroTramite
								WHERE
									st.uIdPersona = mm.uIdPersona
								ORDER BY
									st.dFechaHoraReg DESC
						),
	[dFechaTramite] = (
								SELECT TOP 1 st.dFechaHoraReg FROM SimTramite st 
								JOIN SimNacionalizacion snac ON st.sNumeroTramite = snac.sNumeroTramite
								WHERE
									st.uIdPersona = mm.uIdPersona
								ORDER BY
									st.dFechaHoraReg DESC
						),
	[sEstadoActual] = (
								SELECT TOP 1 stn.sEstadoActual FROM SimTramite st 
								JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
								JOIN SimNacionalizacion snac ON st.sNumeroTramite = snac.sNumeroTramite
								WHERE
									st.uIdPersona = mm.uIdPersona
								ORDER BY
									st.dFechaHoraReg DESC
						)
	INTO #tmp_final
FROM #tmp_uId_mm_ext_nacper mm
JOIN SimPersona sper ON mm.uIdPersona = sper.uIdPersona

SELECT * FROM #tmp_final

-- Test ...
SELECT 
	[sTipoTramite] = stt.sDescripcion,
	[nTotal] = COUNT(1)
FROM SimTramite st 
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE st.sNumeroTramite IN (
	SELECT f.sNumeroTramite FROM #tmp_final f WHERE f.sNumeroTramite IS NOT NULL
)
GROUP BY
	stt.sDescripcion
ORDER BY
	[nTotal] DESC
