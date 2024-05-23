USE SIM
GO


-- 1: C.E. `uId` único ...
/*
	62  | INSCR.REG.CENTRAL EXTRANJERÍA
	58  | CAMBIO DE CALIDAD MIGRATORIA
	118 | EXPEDICIÓN DE CARNÉ DE EXTRANJERÍA
--==========================================================================================================================*/
SELECT * FROM (

	SELECT 
		sce.*,
		[sTipoTramite] = stt.sDescripcion,
		[nContar_UID] = COUNT(sce.uIdPersona) OVER (PARTITION BY sce.uIdPersona),
		[nContar_CE] = COUNT(sce.sNumeroCarnet) OVER (PARTITION BY sce.sNumeroCarnet)
	FROM SimCarnetExtranjeria sce
	JOIN SimTramite st ON sce.sNumeroTramite = st.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	WHERE
		sce.bAnulado = 0
		AND sce.bDuplicado = 0
		AND st.nIdTipoTramite IN (58, 62, 118)
		-- AND st.nIdTipoTramite IN (58)
		AND DATEDIFF(DD, GETDATE(), sce.dFechaCaducidad) > 0

) sce2
WHERE
	sce2.nContar_UID >= 2
	AND sce2.nContar_CE = 1
ORDER BY
	sce2.uIdPersona ASC
--==========================================================================================================================


-- 2: C.E. `uId` distinto ...
/*
	62  | INSCR.REG.CENTRAL EXTRANJERÍA
	58  | CAMBIO DE CALIDAD MIGRATORIA
	118 | EXPEDICIÓN DE CARNÉ DE EXTRANJERÍA
--==========================================================================================================================*/*/

-- 1: Aux ...
-- 1.1
DROP TABLE IF EXISTS #tmp_SimExtranjero
SELECT sper.* INTO #tmp_SimExtranjero FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND (sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND sper.sIdPaisNacionalidad IS NOT NULL)

-- Index 
CREATE INDEX IX_tmp_SimExtranjero_uIdPersona
    ON dbo.#tmp_SimExtranjero(uIdPersona)

-- 1.2
DROP TABLE IF EXISTS #tmp_SimExtranjero_2masregistros
SELECT 
	[uIdPersona_e1] = e1.uIdPersona,
	[sPaterno_e1] = e1.sPaterno,
	[sMaterno_e1] = e1.sMaterno,
	[sNombre_e1] = e1.sNombre,
	[sSexo_e1] = e1.sSexo,
	[dFechaNacimiento_e1] = e1.dFechaNacimiento,
	[sIdPaisNacionalidad_e1] = e1.sIdPaisNacionalidad,

	[uIdPersona_e2] = e2.uIdPersona,
	[sPaterno_e2] = e2.sPaterno,
	[sMaterno_e2] = e2.sMaterno,
	[sNombre_e2] = e2.sNombre,
	[sSexo_e2] = e2.sSexo,
	[dFechaNacimiento_e2] = e2.dFechaNacimiento,
	[sIdPaisNacionalidad_e2] = e2.sIdPaisNacionalidad
	INTO #tmp_SimExtranjero_2masregistros
FROM #tmp_SimExtranjero e1
JOIN #tmp_SimExtranjero e2 ON e1.uIdPersona != e2.uIdPersona
							  AND e1.sPaterno = e2.sPaterno
							  AND (e1.sMaterno = e2.sMaterno)
							  AND (e1.sNombre LIKE '%' + e2.sNombre + '%' OR e2.sNombre LIKE '%' + e1.sNombre + '%')
							  AND e1.sSexo = e2.sSexo
							  AND (
										(e1.dFechaNacimiento = e2.dFechaNacimiento)
										OR
										(
											DAY(e1.dFechaNacimiento) != DAY(e2.dFechaNacimiento)
											AND MONTH(e1.dFechaNacimiento) = MONTH(e2.dFechaNacimiento)
											AND YEAR(e1.dFechaNacimiento) = YEAR(e2.dFechaNacimiento)
										)
										OR
										(
											DAY(e1.dFechaNacimiento) = DAY(e2.dFechaNacimiento)
											AND MONTH(e1.dFechaNacimiento) != MONTH(e2.dFechaNacimiento)
											AND YEAR(e1.dFechaNacimiento) = YEAR(e2.dFechaNacimiento)
										)
										/*OR
										(
											DAY(e1.dFechaNacimiento) = DAY(e2.dFechaNacimiento)
											AND MONTH(e1.dFechaNacimiento) = MONTH(e2.dFechaNacimiento)
											AND YEAR(e1.dFechaNacimiento) != YEAR(e2.dFechaNacimiento)
										)*/
							  )
							  AND e1.sIdPaisNacionalidad = e2.sIdPaisNacionalidad

-- 1.3: Generar `sIdPersona` ...
DROP TABLE IF EXISTS #tmp_SimExtranjero_2masregistros_sId
SELECT
	[sIdPersona] = (
						CONCAT(
							e.sPaterno_e1,
							e.sMaterno_e1,
							e.sNombre_e1,
							e.sSexo_e1,

							(
								CASE
									WHEN e.dFechaNacimiento_e1 = e.dFechaNacimiento_e2 THEN CAST(CAST(e.dFechaNacimiento_e1 AS FLOAT) AS INT)
									WHEN (
											DAY(e.dFechaNacimiento_e1) != DAY(e.dFechaNacimiento_e2)
											AND MONTH(e.dFechaNacimiento_e1) = MONTH(e.dFechaNacimiento_e2)
											AND YEAR(e.dFechaNacimiento_e1) = YEAR(e.dFechaNacimiento_e2)
										 ) THEN CONCAT(MONTH(e.dFechaNacimiento_e1), YEAR(e.dFechaNacimiento_e2))
									WHEN (
											DAY(e.dFechaNacimiento_e1) = DAY(e.dFechaNacimiento_e2)
											AND MONTH(e.dFechaNacimiento_e1) != MONTH(e.dFechaNacimiento_e2)
											AND YEAR(e.dFechaNacimiento_e1) = YEAR(e.dFechaNacimiento_e2)
										 ) THEN CONCAT(DAY(e.dFechaNacimiento_e1), YEAR(e.dFechaNacimiento_e2))
									WHEN (
											DAY(e.dFechaNacimiento_e1) = DAY(e.dFechaNacimiento_e2)
											AND MONTH(e.dFechaNacimiento_e1) = MONTH(e.dFechaNacimiento_e2)
											AND YEAR(e.dFechaNacimiento_e1) != YEAR(e.dFechaNacimiento_e2)
										 ) THEN CONCAT(DAY(e.dFechaNacimiento_e1), MONTH(e.dFechaNacimiento_e2))
								END
							
							),
							e.sIdPaisNacionalidad_e1
						)

	),
	e.*
	INTO #tmp_SimExtranjero_2masregistros_sId
FROM #tmp_SimExtranjero_2masregistros e

-- 1.3.1: 
UPDATE #tmp_SimExtranjero_2masregistros_sId
	SET sIdPersona = REPLACE(sIdPersona, ' ', '')

-- Test ...
SELECT TOP 10 * FROM #tmp_SimExtranjero_2masregistros_sId e ORDER BY e.sIdPersona

-- Index ...
CREATE INDEX IX_tmp_SimExtranjero_2masregistros_sId_sIdPersona
    ON dbo.#tmp_SimExtranjero_2masregistros_sId(sIdPersona)

CREATE INDEX IX_tmp_SimExtranjero_2masregistros_sId_uIdPersona_e1
    ON dbo.#tmp_SimExtranjero_2masregistros_sId(uIdPersona_e1)

-- 2: ...
SELECT 
	sce3.*
FROM (

	SELECT 
		sce2.*,
		[nContar_sID2] = COUNT(sce2.sIdPersona) OVER (PARTITION BY sce2.sIdPersona)
	FROM (

		SELECT 
			e.sIdPersona,
			e.sNombre_e1,
			e.sPaterno_e1,
			e.sMaterno_e1,
			e.sSexo_e1,
			e.dFechaNacimiento_e1,
			e.sIdPaisNacionalidad_e1,
			sce.*,
			[nContar_SID] = COUNT(e.sIdPersona) OVER (PARTITION BY e.sIdPersona),
			[nContar_CE] = ROW_NUMBER() OVER (PARTITION BY sce.sNumeroCarnet ORDER BY sce.dFechaEmision)
		FROM SimCarnetExtranjeria sce
		JOIN #tmp_SimExtranjero_2masregistros_sId e ON sce.uIdPersona = e.uIdPersona_e1
		JOIN SimTramite st ON sce.sNumeroTramite = st.sNumeroTramite
		WHERE
			sce.bAnulado = 0
			AND sce.bDuplicado = 0
			-- AND st.nIdTipoTramite IN (58, 62, 118)
			AND DATEDIFF(DD, GETDATE(), sce.dFechaCaducidad) > 0 -- Vigentes ...

	) sce2
	WHERE
		sce2.nContar_SID >= 2 AND sce2.nContar_CE = 1
) sce3
WHERE
	sce3.nContar_sID2 >= 2
ORDER BY
	sce3.sIdPersona ASC


-- Test ...
SELECT DATEDIFF(DD, GETDATE(), '2023-09-15')

SELECT CAST(CAST(GETDATE() AS FLOAT) AS INT)
SELECT CAST(CAST(CAST(GETDATE() AS FLOAT) AS INT) AS DATETIME) + 2
