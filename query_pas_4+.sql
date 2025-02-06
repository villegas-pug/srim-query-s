USE SIM
GO

/*► Total PAS-E por persona ... */
/*====================================================================================*/
--SELECT * FROM #total_pas_by_per WHERE nTotalPas >= 4
DROP TABLE IF EXISTS #total_pas_by_per
;WITH cte_pas AS (
	SELECT
		st.uIdPersona,
		st.sNumeroTramite
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
		AND LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
), cte_total_pas AS (
	SELECT 
		p.uIdPersona,
		COUNT(p.sNumeroTramite)[nTotalPas]
	FROM cte_pas p
	GROUP BY p.uIdPersona
) SELECT * INTO #total_pas_by_per FROM cte_total_pas

-- Index
CREATE NONCLUSTERED INDEX ix_total_pas_by_per_uIdPersona
ON #total_pas_by_per(uIdPersona)
/*====================================================================================*/

/*► Ultimo MovMig por persona ... */
/*====================================================================================*/
--SELECT * FROM #total_pas_by_per WHERE nTotalPas >= 4
DROP TABLE IF EXISTS #ult_movmig_by_per
;WITH cte_pas AS (
	SELECT
		st.uIdPersona,
		ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY spas.dFechaHoraAud)nRow_pas
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
		AND LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
), cte_pas_4mas AS (
	SELECT * FROM cte_pas p WHERE p.nRow_pas >= 4
), cte_pas_join_mm AS (
	SELECT
		spas.uIdPersona,
		smm.sTipo [sTipoMovimiento],
		smm.dFechaControl,
		smm.sIdPaisMov,
		ROW_NUMBER() OVER (PARTITION BY spas.uIdPersona ORDER BY smm.dFechaControl DESC)nRow_mm
 	FROM cte_pas_4mas spas
	JOIN SimMovMigra smm ON spas.uIdPersona = smm.uIdPersona
), cte_ult_mm AS (
	SELECT 
		p.uIdPersona,
		p.sTipoMovimiento,
		p.dFechaControl,
		p.sIdPaisMov
	FROM cte_pas_join_mm p
	WHERE p.nRow_mm = 1
) SELECT * INTO #ult_movmig_by_per FROM cte_ult_mm

-- Index
CREATE NONCLUSTERED INDEX ix_ult_movmig_by_per
ON #ult_movmig_by_per(uIdPersona)
/*====================================================================================*/

/*► ... */
/*========================================================================================================================*/
;WITH cte_pas AS (
	SELECT
		st.uIdPersona,
		spas.*,
		ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY spas.dFechaHoraAud)nRow_pas
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
		AND LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
), cte_pas_4mas AS (
	SELECT * FROM cte_pas p WHERE p.nRow_pas >= 4
), cte_pas_join_pas4mas AS (
	SELECT p.* FROM (SELECT DISTINCT uIdPersona FROM cte_pas_4mas) _4mas
	JOIN cte_pas p ON _4mas.uIdPersona = p.uIdPersona
), cte_apply_field_nTotalPas AS (
	SELECT 
		[nTotalPas-E] = (SELECT nTotalPas FROM #total_pas_by_per WHERE uIdPersona = pas.uIdPersona),
		pas.*
	FROM cte_pas_join_pas4mas pas
), cte_pas_adicional AS (
	SELECT 
		pas.*,
		su.sNombre [sUbigeo_Actual],
		se.sDomicilio [sDirecciónActual],
		sprof.sDescripcion [sOcupacionActual],
		[nCatidadMovMig] = (SELECT COUNT(1) FROM SimMovMigra WHERE uIdPersona = pas.uIdPersona),
		[sTipoUltimo_mm] = (SELECT mm.sTipoMovimiento FROM #ult_movmig_by_per mm WHERE mm.uIdPersona = pas.uIdPersona),
		[dUltimaFecha_mm] = (SELECT mm.dFechaControl FROM #ult_movmig_by_per mm WHERE mm.uIdPersona = pas.uIdPersona),
		[sUltProcDest_mm] = (SELECT mm.sIdPaisMov FROM #ult_movmig_by_per mm WHERE mm.uIdPersona = pas.uIdPersona)
	FROM cte_apply_field_nTotalPas pas
	JOIN SimPersona sp ON pas.uIdPersona = sp.uIdPersona
	LEFT OUTER JOIN SimExtranjero se ON pas.uIdPersona = se.uIdPersona
	LEFT OUTER JOIN SimProfesion sprof ON sp.sIdProfesion = sprof.sIdProfesion
	LEFT OUTER JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
) SELECT * FROM cte_pas_adicional

/*► Test ...*/
SELECT * FROM SimPasaporte spas
JOIN SImTramite st ON spas.sNumeroTramite = st.sNumeroTramite
WHERE
	st.uIdPersona = '0CC0D693-D090-41C6-BAFD-CAE3765A9003' --CAMPOS	NUÑEZ, HUGO ARMANDO
ORDER BY spas.dFechaHoraAud DESC

/*► Todos pasaporte ...*/
SELECT 
	spas.sPasNumero,
	spas.sNumeroTramite,
	spas.sObservaciones,
	spas.dFechaEmision,
	spas.dFechaRevalidacion,
	spas.dFechaExpiracion,
	spas.dFechaAnulacion,
	spas.sEstadoActual,
	spas.bFallaControl,
	spas.sPaterno,
	spas.sMaterno,
	spas.sNombre,
	spas.sIdPaisNacimiento,
	spas.sSexo,
	spas.dFechaNacimiento,
	spas.sIdDocumento,
	spas.sNumeroDoc,
	spas.sIdDependencia,
	spas.dFechaTramite,
	spas.sTipoControl,
	spas.nIdMotAnulacion
FROM SimPasaporte spas
WHERE
	spas.sEstadoActual = 'E'
	AND spas.dFechaEmision >= '2016-01-01 00:00:00'
	AND LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
	--AND spas.sPasNumero LIKE '1%'
	AND spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
ORDER BY
	spas.dFechaEmision
/*========================================================================================================================*/