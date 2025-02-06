USE SIM
GO

SELECT * FROM (

	SELECT 
		-- smm.*,
		smm.dFechaControl,
		[sTipoControl] = smm.sTipo,
		[sProc/Destino] = smm.sIdPaisMov,
		sper.sNombre,
		sper.sPaterno,
		sper.sMaterno,
		[sSexo] = sper.sSexo,
		[dFechaNacimiento] = sper.dFechaNacimiento,
		[sNacionalidad] = sp.sNombre,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN SImPersona sper ON smm.uIdPersona = sper.uIdPersona
	JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
	WHERE
		smm.sTipo IN ('E', 'S')
		AND smm.dFechaControl BETWEEN DATEADD(DD,-30, GETDATE()) AND GETDATE()
		AND smm.sIdPaisNacionalidad IN (
			'ISR',
			'JOR',
			'KUW',
			'LBA',
			'OMA',
			'PAL',
			'QAT',
			'SIR',
			'YRA',
			'CHP',
			'TUR'
		)
		/*AND smm.sIdPaisNacionalidad IN (
		'COL',
		'BOL',
		'CUB',
		'ASA',
		'ARL',
		'BAH',
		'DJI',
		'EGI',
		'EAU',
		'IRN',
		'IRK'
	)*/

) mm
WHERE
	mm.nFila_mm = 1
	-- AND mm.sTipoControl = 'E'
	


-- Test
/*
-- COL	COLOMBIA
-- BOL	BOLIVIA
-- CUB	CUBA
-- ASA	ARABIA SAUDITA
	ARL	ARGELIA
	BAH	BAHREIN
	DJI	DJIBOUTI
	EGI	EGIPTO
	EAU	EMIRATOS ARABES UNID
	IRN	IRAN
	IRK	IRAQ

	ISR	ISRAEL
	JOR	JORDANIA
	KUW	KUWAIT
	LBA	LIBANO
	OMA	OMAN
	PAL	PALESTINA
	QAT	QATAR
	SIR	SIRIA
	YRA	YEMEN
	CHP	CHIPRE
	TUR	TURQUIA

*/


SELECT * FROM SimPais sp
WHERE	
	sp.sNombre LIKE '%Turqu%'