USE SIM
GO

/*░

	STEP-01 → Extraer extranjeros permanecen en territorio nacional


*/

-- » 1.1: Extrae ciudadanos extranjeros permanecen en terririo nacional ...

DROP TABLE IF EXISTS #tmp_ctrlmig_permanecen
SELECT * INTO #tmp_ctrlmig_permanecen FROM (

	SELECT 
		smm.uIdPersona,
		sp.sNombre,
		sp.sPaterno,
		sp.sMaterno,
		sp.sSexo,
		sp.dFechaNacimiento,
		sp.sNumDocIdentidad,
		sp.sIdPaisNacionalidad,
		sp.sIdPaisNacimiento,

		-- MovMig
		[sTipoControl] = smm.sTipo,
		smm.dFechaControl,
		[sProcDest] = smm.sIdPaisMov,

		-- Aux
		[nRow_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)

	FROM SimMovMigra smm
	JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona
	WHERE
		smm.bAnulado = 0
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjeros ...
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

) mm
WHERE
	mm.nRow_mm = 1
	-- AND mm.sTipoControl = 'E'

-- » 1.2: Agrupa a ciudadanos extranjeros con atributos identicos ...
DROP TABLE IF EXISTS #tmp_ctrlmig_permanecen_group
SELECT 
	cm.sPaterno,
	cm.sMaterno,
	cm.dFechaNacimiento,
	cm.sIdPaisNacionalidad,
	cm.sSexo,
	[nCantCoincidencia] = COUNT(1)

	INTO #tmp_ctrlmig_permanecen_group
FROM #tmp_ctrlmig_permanecen cm
GROUP BY
	cm.sPaterno,
	cm.sMaterno,
	cm.dFechaNacimiento,
	cm.sIdPaisNacionalidad,
	cm.sSexo
HAVING
	COUNT(1) > 1

-- Test
SELECT SUM(g.nCantCoincidencia) FROM #tmp_ctrlmig_permanecen_group g

-- » 1.3: Extrae extranjeros que permanecen en le perú, con más de 1 identidad ...
DROP TABLE IF EXISTS #tmp_ctrlmig_perm_masidentidad
SELECT * INTO #tmp_ctrlmig_perm_masidentidad FROM #tmp_ctrlmig_permanecen p
WHERE
	EXISTS(

		SELECT 1 FROM #tmp_ctrlmig_permanecen_group g
		WHERE
			p.sPaterno = g.sPaterno AND p.sMaterno = g.sMaterno
			AND p.dFechaNacimiento = g.dFechaNacimiento
			AND p.sIdPaisNacionalidad = g.sIdPaisNacionalidad
			AND p.sSexo = g.sSexo

	)
ORDER BY
	p.sPaterno,
	p.sMaterno,
	p.dFechaNacimiento,
	p.sIdPaisNacionalidad,
	p.sSexo

-- Test
SELECT TOP 100 * FROM #tmp_ctrlmig_perm_masidentidad
SELECT COUNT(1) FROM #tmp_ctrlmig_perm_masidentidad

-- » 1.4: Extracción de ciudadanos con más de 1 identidad ...

;WITH tmp_ctrlmig_perm_masident AS (-- Extranjeros con más de 1 identidad

	SELECT
		cm.*,
		[nRow_masidentidad] = ROW_NUMBER() OVER (
									PARTITION BY
										cm.sPaterno,
										cm.sMaterno,
										cm.dFechaNacimiento,
										cm.sIdPaisNacionalidad,
										cm.sSexo
									ORDER BY
										cm.dFechaControl DESC
								)
	FROM #tmp_ctrlmig_perm_masidentidad cm

), tmp_ctrlmig_perm_masident_excede AS (-- Anteriores registros migratorios con otras identidades ...

	SELECT * FROM tmp_ctrlmig_perm_masident cm
	WHERE
		cm.nRow_masidentidad > 1 -- Penultimo registro migratorio ...

), tmp_ctrlmig_perm_masident_ultimaident AS (-- uLtimo registro migratorio con una de las identidades ...

	SELECT * FROM tmp_ctrlmig_perm_masident cm
	WHERE
		cm.nRow_masidentidad = 1 -- Ultimo registro migratorio ...

) SELECT * INTO tmp_ctrlmig_permanecen FROM #tmp_ctrlmig_permanecen cmp
WHERE
	NOT EXISTS (
	
		SELECT 1 FROM tmp_ctrlmig_perm_masident_excede cmpe
		WHERE
			cmpe.uIdPersona = cmp.uIdPersona
	)

-- Resultado: 1,165,921

-- Cleanup
DROP TABLE tmp_ctrlmig_permanecen





-- ...
SELECT * FROM SimMovMigra smm
WHERE
	-- smm.sIdPaisNacionalidad = 'PER'
	smm.sNumeroDoc = '118661150'

SELECT * FROM BD_SIRIM.dbo.RimPasaporte spas
WHERE
	spas.sNumeroPasaporte IN ('116224605', '120233515')

SELECT * FROM SIM.dbo.SimMovMigra smm
WHERE
	smm.sNumeroDoc IN ('116224605', '120233515')


-- ALEJANDRA HAYDEE VELASQUEZ ERQUIAGA
SELECT ss.* FROM SimPersona sp
JOIN SimSesion ss ON sp.nIdSesion = ss.nIdSesion
WHERE
	-- sp.sNombre LIKE '%ALEJAND%'
	sp.sPaterno LIKE '%VELASQ%'
	AND sp.sMaterno LIKE '%ERQUI%'
	AND sp.dFechaNacimiento = '1997-08-06'


-- STEP-01: Tabla `tmp`
-- SimPersona
DROP TABLE IF EXISTS tmp_pas_paísnnn
CREATE TABLE tmp_pas_paísnnn
(
	nId INT PRIMARY KEY NOT NULL,
	sNombres VARCHAR(99)NULL ,
	sMaterno VARCHAR(99)NULL ,
	sPaterno VARCHAR(99)NULL ,
	sSexo CHAR(1) NULL,
	dFechaNacimiento DATETIME NULL,
	sIdNacionalidad CHAR(3) NULL
)

SELECT 
	TOP 0
	[nId] = 0,
	sNombre,
	sPaterno,
	sMaterno,
	sSexo,
	dFechaNacimiento,
	sIdPaisNacionalidad
	INTO tmp_pas_paísnnn 
FROM SimPersona



-- Index ...
CREATE INDEX ix_tmp_pas_paísnnn_sMaterno_sPaterno_sSexo_dFecNac_sIdNac
    ON dbo.tmp_pas_paísnnn(sPaterno, sSexo, dFechaNacimiento, sIdNacionalidad)


-- STEP-02: ...
-- TRUNCATE TABLE tmp_pas_paísnnn
-- SELECT * FROM tmp_pas_paísnnn
-- INSERT INTO tmp_pas_paísnnn VALUES(

SELECT CAST(GETDATE() AS FLOAT)

-- STEP-03: ...
SELECT 
	sp.uIdPersona, 
	pas.*,
	[dFechaCreación] = ss.dFechaFin,
	[sModuloOrigen] = ss.sIdModulo,
	[sModulo] = sm.sDescripcion,
	[sOperador] = su.sNombre,
	[¿Tiene biometría?] = IIF(
								EXISTS(
									SELECT TOP 1 1 FROM SimPersonaNoAutorizada spna
									JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
									WHERE
										spna.sNumDocIdentidad = sp.sNumeroDoc
										AND spna.sIdPaisNacionalidad = sp.sIdPaisNacionalidad
								),
								'Si',
								'No'
							)
FROM tmp_pas_paísnnn pas
JOIN SimPersona sp ON pas.sPaterno = sp.sPaterno
				   -- AND pas.sMaterno = sp.sMaterno
				   AND pas.dFechaNacimiento = sp.dFechaNacimiento
				   AND pas.sSexo = sp.sSexo
				   AND pas.sIdPaisNacionalidad = sp.sIdPaisNacionalidad	
JOIN SimSesion ss ON sp.nIdSesion = ss.nIdSesion
JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
ORDER BY
	sp.sPaterno, 
	sp.dFechaNacimiento, 
	sp.sSexo, 
	sp.sIdPaisNacionalidad


SELECT COUNT(1) FROM [dbo].[SimDedoBio]
SELECT COUNT(1) FROM [dbo].[SimMovMigraTkBio]
SELECT TOP 1 * FROM SimExtranjero
SELECT TOP 10000 * FROM [dbo].[SimImagen]
SELECT TOP 1 * FROM [dbo].[SimFisonomia]
[dbo].[xTotalExtranjerosPeru]

SELECT * FROM SimMovMigra smm
WHERE
	smm.uIdPersona = '6F772A46-8AD5-4FC5-BB65-C8E57E15DB09'
ORDER BY
	smm.dFechaControl DESC