USE SIM
GO

--STEP-1
SELECT 
	* 
FROM [dbo].[SimPasaporte] spas
WHERE 
	spas.sNombre LIKE '%mar%'
	AND spas.sPaterno LIKE 'PALACIOS'
	AND spas.sMaterno LIKE 'HUAMAN'

-- STEP-02
SELECT 
	* 
FROM BD_SIRIM.dbo.RimPasaporte spas
WHERE 
	spas.sNombre LIKE '%mar%'
	AND spas.sApePat LIKE 'PALACIOS'
	AND spas.sApeMat LIKE 'HUAMAN'


-- STEP-03: Control Migra
-- 3C0883CB-1AC7-4814-8A08-94CC98FE1C4D | PALACIOS	HUAMAN	MARGOT | 1983-11-18
SELECT 
	sp.* 
FROM SimPersona sp
WHERE 
	sp.uIdPersona = '3C0883CB-1AC7-4814-8A08-94CC98FE1C4D'
	/*sp.sNombre LIKE '%mar%'
	AND sp.sPaterno LIKE '%PALACIOS%'
	AND sp.sMaterno LIKE '%HUAMAN%'*/
	

-- STEP-01: Extrae pasaportes diplomaticos ...
--1.1
DROP TABLE IF EXISTS #tmp_pasdip
SELECT 
	* 
	INTO #tmp_pasdip
FROM [dbo].[SimDocPersona] sdp
WHERE 
	sdp.sIdDocumento = 'PAS'
	AND sdp.sNumero LIKE 'D%'
	AND sdp.sNumero NOT LIKE '_%[a-zA-Z ]%'
	AND sdp.sNumero NOT LIKE '%[*-?]%'
	AND LEN(RTRIM(LTRIM(sdp.sNumero))) = 9 
	-- AND PATINDEX('% %', sdp.sNumero) = 0

-- 1.2: Eliminar duplicados ...
DROP TABLE IF EXISTS #tmp_pasdip_u
SELECT * INTO #tmp_pasdip_u FROM (

	SELECT 
		*,
		[nFila_d] = ROW_NUMBER() OVER (PARTITION BY pas.uIdPersona, pas.sNumero ORDER BY pas.dFechaHoraAud DESC)
	FROM #tmp_pasdip pas

) pd
WHERE pd.nFila_d = 1

-- Test ...
--STEP-02: Pas-D tienen control migratorio ...
SELECT TOP 1 * FROM #tmp_pasdip_u

ALTER TABLE #tmp_pasdip_u
	ADD sTieneControl CHAR(2)

UPDATE #tmp_pasdip_u
	SET sTieneControl = IIF(
							EXISTS(SELECT 1 FROM SimMovMigra smm 
									WHERE 
										smm.uIdPersona = uIdPersona 
										AND smm.sNumeroDoc = sNumero),
							'Si',
							'No'
						)

--STEP-Final: Adicionar DNI ...
SELECT pas.* FROM #tmp_pasdip_u_movmig pas 
JOIN SimPersona sp ON pas.uIdPersona = sp.uIdPersona
WHERE pas.sNumDocCOntrol = 'D16004451'


DROP TABLE IF EXISTS #tmp_pasdip_u_movmig
SELECT * INTO #tmp_pasdip_u_movmig FROM (

	SELECT 
		d.uIdPersona,
		smm.sNombres,
		[sDocControl] = smm.sIdDocumento,
		[sNumDocControl] = smm.sNumeroDoc,
		[sDoc_Persona] = sp.sNumeroDni,
		[sNumIdentidad_Pesona] = CONCAT('''', sp.sNumeroDni),
		smm.dFechaControl,
		[sControl] = smm.sTipo,
		[sOrigenDestino] = smm.sIdPaisMov,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	RIGHT JOIN #tmp_pasdip_u d ON smm.uIdPersona = d.uIdPersona AND smm.sNumeroDoc = d.sNumero
	LEFT JOIN SimPersonaNacional sp ON sp.uIdPersona = d.uIdPersona
	WHERE
		-- smm.bAnulado = 0
		d.sTieneControl = 'Si'
		-- AND d.dFechaHoraAud >= '2016-01-01 00:00:00.000'

) d
WHERE
	d.nFila_mm = 1


-- Congresistas: Extraer a congresistas con PAS-D no vinculados a DNI ...
-- 1
SELECT * FROM #tmp_pasdip_u_movmig

-- 2: Crear tabla `tmp`
DROP TABLE #tmp_congresista
CREATE TABLE #tmp_congresista 
(
	sNombre VARCHAR(100) NULL,
	sNumeroDoc CHAR(8) NULL,
	Nombres VARCHAR(100) NULL,
	PrimeroApe VARCHAR(100) NULL,	
	SegundoApe VARCHAR(100) NULL
)

-- 3: Bulk ...
-- INSERT INTO #tmp_congresista VALUES()
-- TRUNCATE TABLE #tmp_congresista



-- 4: Final ...
-- SELECT * FROM #tmp_pasdip_u_movmig
SELECT * FROM #tmp_congresista c WHERE c.sNumeroDoc = '06354697'
SELECT TOP 1 * FROM SimPersonaNacional
SELECT * FROM #tmp_pasdip_u_movmig


-- Final: Congresistas con pas-d ...
SELECT * FROM (

	SELECT 
		d.uIdPersona,
		[sNombre_congresita] = c.sNombre,
		spn.sNombre,
		spn.sApellidoPrimero,
		spn.sApellidoSegundo,
		[sNumeroDni] = CONCAT('''', spn.sNumeroDni),
		spn.dFechaNacimiento,
		d.dFechaControl,
		d.sDocControl,
		d.sControl,
		d.sNumDocControl
	FROM #tmp_pasdip_u_movmig d
	JOIN SimPersonaNacional spn ON d.uIdPersona = spn.uIdPersona
	JOIN #tmp_congresista c ON spn.sNumeroDni = c.sNumeroDoc

) c2

-- Final: Congresistas con pas-d no vincualdos ...
SELECT * FROM (

	SELECT 
		d.uIdPersona,
		[sNombre_congresita] = c.sNombre,
		spn.sNombre,
		spn.sPaterno,
		spn.sMaterno,
		[sNumeroDni] = CONCAT('''', spn.sNumDocIdentidad),
		spn.dFechaNacimiento,
		d.dFechaControl,
		d.sDocControl,
		d.sControl,
		d.sNumDocControl
	FROM #tmp_pasdip_u_movmig d
	JOIN SimPersona spn ON d.uIdPersona = spn.uIdPersona
	JOIN #tmp_congresista c ON spn.sNombre = UPPER(c.Nombres)
							AND spn.sPaterno = UPPER(c.PrimeroApe)
							AND spn.sMaterno = UPPER(c.SegundoApe)
	WHERE
		spn.sIdPaisNacionalidad = 'PER'

) c2

SELECT * FROM #tmp_congresista
















SELECT TOP 10 * FROM SimPersonaNacional sp
WHERE 
	-- sp.sNumeroDni = '42134579'
	sp.sNombre = 'Margot'
	AND sp.sApellidoPrimero = 'Palacios'
	AND sp.sApellidoSegundo LIKE 'Huam%'


SELECT * FROM SimPersonaNacional WHERE uIdPersona = '3C0883CB-1AC7-4814-8A08-94CC98FE1C4D'

SELECT * FROM #tmp_congresista c
WHERE 
	c.Nombres = 'Margot'
	AND c.PrimeroApe = 'Palacios'
	AND c.SegundoApe LIKE 'Huam%'

SELECT * FROM SimPersona sp
WHERE 
	-- sp.sNumeroDni = '42134579'
	sp.sNombre = 'Margot'
	AND sp.sPaterno = 'Palacios'
	AND sp.sMaterno LIKE 'Huam%'














































-- Kazajistán y Macedonia
-- KAZ | KAZAJSTAN ; MAC | EX R.YUG.MACEDONIA
SELECT 
	[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
	[sProcDestino] = spa.sNombre,
	[sTipoControl] = smm.sTipo,
	[nTotal] = COUNT(1)
FROM SimMovMigra smm
JOIN SimPais spa ON smm.sIdPaisMov = spa.sIdPais
WHERE
	smm.bAnulado = 0
	AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	AND smm.sTipo IN ('E', 'S')
	AND smm.sIdPaisNacionalidad = 'PER'
	AND smm.sIdPaisMov IN ('KAZ', 'MAC')
GROUP BY
	DATEPART(YYYY, smm.dFechaControl),
	spa.sNombre,
	smm.sTipo