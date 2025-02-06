USE SIM
GO

/*
	'A' → 'ANULADO'
	'C' → 'CONSULAR'
	'E' → 'EMITIDO'
	'N' → 'POR ENTREGAR (EN PROCESO)'
	'R' → 'REVALIDADO'
	'X' → 'CANCELADO'
	PAS-E: 9d */
/*======================================================================================================================================*/
/*► PAS-E nuevos ... */
;WITH cte_pas AS (
	SELECT 
		st.uIdPersona,
		MAX(pas.dFechaEmision)dFechaEmision,
		COUNT(st.sNumeroTramite) nTotalPas
	FROM SimPasaporte pas
	JOIN SimTramite st ON pas.sNumeroTramite = st.sNumeroTramite
	WHERE
		LEN(LTRIM(RTRIM(pas.sPasNumero))) = 9
	GROUP BY
		st.uIdPersona
	HAVING COUNT(st.sNumeroTramite) = 1
), cte_pas_new AS (
	SELECT 
		DATEPART(YYYY, cte.dFechaEmision)nAñoEmision, 
		cte.nTotalPas 
	FROM cte_pas cte
) SELECT * FROM cte_pas_new p
PIVOT (
	COUNT(p.nTotalPas) FOR p.nAñoEmision IN ([2020], [2021], [2022])
) pv

/*► Ultimo PAS-E por persona ...*/
;WITH cte_pas AS (
	SELECT 
		DATEPART(YYYY, spas.dFechaEmision)nAñoEmision,
		st.sNumeroTramite,
		ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY spas.dFechaEmision DESC)nRow_pas
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		spas.sEstadoActual = 'E'
		AND LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
		--AND spas.dFechaEmision >= '2020-01-01 00:00:00'
), cte_ult_pas_e AS (
	SELECT * FROM cte_pas p WHERE p.nRow_pas = 1
) SELECT * FROM cte_ult_pas_e p
PIVOT (
	COUNT(p.sNumeroTramite) FOR p.nAñoEmision IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022])
) pv

/*► RANK: Cantidad de pasaportes por persona ... */
;WITH cte_count_pas AS (
	SELECT 
		st.uIdPersona,
		COUNT(st.sNumeroTramite)nTotalPas
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9 -- PAS-E
	GROUP BY st.uIdPersona
), cte_rank_pas AS (
	SELECT 
		p.nTotalPas,
		COUNT(p.nTotalPas) nTotalCiudadanos
	FROM cte_count_pas p
	GROUP BY p.nTotalPas
) SELECT * FROM cte_rank_pas p 
--WHERE p.nTotalPas >= 5
ORDER BY p.nTotalPas DESC

/*► Total PAS-E emitidos ...*/
;WITH cte_pas AS (
	SELECT 
		DATEPART(YYYY, spas.dFechaEmision)nAñoEmision,
		st.sNumeroTramite
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	WHERE
		--spas.sEstadoActual = 'E'
		LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
		--AND spas.dFechaEmision >= '2020-01-01 00:00:00'
) SELECT * FROM cte_pas p
PIVOT (
	COUNT(p.sNumeroTramite) FOR p.nAñoEmision IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022])
) pv

/*Test ... */
SELECT 
	DATEPART(YYYY, spas.dFechaEmision)nAñoEmision,
	COUNT(st.sNumeroTramite)
FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
WHERE
	LEN(LTRIM(RTRIM(spas.sPasNumero))) = 9
GROUP BY DATEPART(YYYY, spas.dFechaEmision)


/*Test ...*/
/*
	CA7A1254-B9B2-4544-935D-E11F1133DAAA
	8D779528-496C-4312-8F88-C7BD6833EA11
	FF182ECE-9578-4EB7-AC74-CDF4DEB038A3
	BC34B47D-ECDD-4DD0-A62E-CC1614B3F753
	929A6EB7-9F14-4407-93A9-D0B6726E6396
	A3F758C2-CCD0-4364-BC54-3ED08A263298
	F02B3C45-634E-4A44-896E-1F4D58EBFC34
*/
SELECT 
	pas.sEstadoActual,
	pas.dFechaEmision,
	pas.*
FROM SimPasaporte pas
JOIN SimTramite st ON pas.sNumeroTramite = st.sNumeroTramite
WHERE
	st.uIdPersona = 'A3F758C2-CCD0-4364-BC54-3ED08A263298'
/*=======================================================================================================================================*/

SELECT 
	stt.sDescripcion [sTipoTramite],
	[sNumeroPasaporte] = CONCAT('''', spas.sPasNumero),
	spas.*
FROM SimPasaporte spas 
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	st.uIdPersona = '0CC0D693-D090-41C6-BAFD-CAE3765A9003'
ORDER BY
	spas.dFechaEmision DESC

SELECT * FROM SimMovMigra smm
WHERE
	smm.sNumeroDoc IN (
		'118576321',
		'118738533',
		'118574765',
		'118672689',
		'118574460',
		'118556671',
		'118476675',
		'118363186',
		'118180485',
		'116729189',
		'116691933',
		'116636816',
		'116577707',
		'116360645',
		'116200667',
		'4080322',
		'0127839'
)