USE SIM
GO


/*░
-- 1. 
=========================================================================================================================================================================*/

-- 5.1: Aux ...
DROP TABLE IF EXISTS #tmp_SimExtranjero
SELECT sper.* INTO #tmp_SimExtranjero FROM SimPersona sper
WHERE
	sper.bActivo = 1
	-- AND (sper.sIdDocIdentidad IS NOT NULL AND sper.sNumDocIdentidad IS NOT NULL)
	AND (sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND sper.sIdPaisNacionalidad IS NOT NULL)


-- 5.2: Generar `sIdPersona` ...
DROP TABLE IF EXISTS #tmp_SimExtranjero_sId
SELECT
	[sIdPersona] = (
						CONCAT(
							e.sNombre,
							e.sPaterno,
							e.sMaterno,
							e.sSexo,
							-- e.sIdDocIdentidad,
							-- e.sNumDocIdentidad,
							CAST(CAST(e.dFechaNacimiento AS FLOAT) AS INT),
							e.sIdPaisNacionalidad
						)

	),
	e.*
	INTO #tmp_SimExtranjero_sId
FROM #tmp_SimExtranjero e

UPDATE #tmp_SimExtranjero_sId
	SET sIdPersona = REPLACE(sIdPersona, ' ', '')

-- Index ...
CREATE INDEX IX_tmp_SimExtranjero_sId
    ON dbo.#tmp_SimExtranjero_sId(sIdPersona)

-- 5.3: ...
DROP TABLE IF EXISTS #tmp_SimExtranjero_sId_3masregistros
SELECT 
	e2.*
	INTO #tmp_SimExtranjero_sId_3masregistros
FROM (

	SELECT 
		e.sIdPersona,
		e.uIdPersona,
		e.sNombre,
		e.sPaterno,
		e.sMaterno,
		e.sSexo,
		e.sIdDocIdentidad,
		[sNumDocIdentidad] = CONCAT('''', e.sNumDocIdentidad),
		e.dFechaNacimiento,
		e.sIdPaisNacionalidad,
		[nContar_SID] = COUNT(e.sIdPersona) OVER (PARTITION BY e.sIdPersona)
	FROM #tmp_SimExtranjero_sId e

) e2
WHERE
	e2.nContar_SID >= 3

-- 5.4.1: Con CE ...
SELECT 
	sper.*,
	[CE(Vigente)] = (
						IIF(
							EXISTS(
								SELECT TOP 1 1 FROM SimCarnetExtranjeria sce
								WHERE
									sce.uIdPersona = sper.uIdPersona
									AND sce.bAnulado = 0
									AND DATEDIFF(DD, GETDATE(), sce.dFechaCaducidad) > 0
								ORDER BY
									sce.dFechaEmision DESC
							),
							'Si',
							'No'
						)
					)
FROM #tmp_SimExtranjero_sId_3masregistros sper
ORDER BY
	sper.sIdPersona

-- 5.4.2: Con CE ...
SELECT 
	sper.*
FROM #tmp_SimExtranjero_sId_3masregistros sper
WHERE
	EXISTS(
			SELECT TOP 1 1 FROM SimCarnetExtranjeria sce
			WHERE
				sce.uIdPersona = sper.uIdPersona
				AND sce.bAnulado = 0
				AND DATEDIFF(DD, GETDATE(), sce.dFechaCaducidad) > 0
			ORDER BY
				sce.dFechaEmision DESC
	)
ORDER BY
	sper.sIdPersona

-- SELECT TOP 100 * FROM SimCarnetExtranjeria

SELECT DATEDIFF(DD, GETDATE(), '2023-10-15')

SELECT 
	sper.*
FROM #tmp_SimExtranjero_sId_3masregistros sper
WHERE
	sper.sIdPersona = 'SONIADIASBATISTACHAVEZSEPULVEDAF18949BRA'
	-- sper.uIdPersona = 'F8F7EF79-DFA1-4260-A982-1C4CE72053FF'
	

-- 34B00803-7008-45B0-B682-2DBED63F9195
-- ANIANOALFREDODELEONGEOVOM16756VEN

--=======================================================================================================================================================================*/