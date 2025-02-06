USE SIM
GO

SELECT COUNT(1) FROM SimPersona sper -- 42,369,053
SELECT COUNT(1) FROM SimExtranjero -- 5,401,105
SELECT COUNT(1) FROM SimPeruano -- 9,601,514

-- Extranjeros:
-- Nacionalidad → 31,052,982 ...
-- Nacimiento   → 32,130,562

-- Aux: `tmp` Extranjeros ...
DROP TABLE IF EXISTS #tmp_simperuanos
SELECT 
	sper.uIdPersona,
	[sNombre] = LTRIM(RTRIM(sper.sNombre)),
	[sPaterno] = LTRIM(RTRIM(sper.sPaterno)),
	[sMaterno] = LTRIM(RTRIM(sper.sMaterno)),
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad,
	sper.sIdPaisNacimiento,
	sper.nIdSesion
	INTO #tmp_simperuanos
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	-- AND (sper.sNombre != '' AND sper.sNombre IS NOT NULL)
	-- AND (sper.sPaterno != '' AND sper.sPaterno IS NOT NULL)
	-- AND (sper.dFechaNacimiento != '' AND sper.dFechaNacimiento IS NOT NULL)
	AND sper.sIdPaisNacionalidad = 'PER'
	-- AND sper.sIdPaisNacimiento  = 'PER'

-- Test ...
SELECT TOP 1000 * FROM #tmp_simperuanos
SELECT COUNT(1) FROM #tmp_simperuanos

-- Index's ...
CREATE NONCLUSTERED INDEX IX_tmp_simperuanos_uIdPersona
    ON dbo.#tmp_simperuanos(uIdPersona)

CREATE NONCLUSTERED INDEX IX_tmp_simperuanos_sNombre_sPaterno_sMaterno_sSexo_dFechaNacimiento_sIdPaisNacionalidad
    ON dbo.#tmp_simperuanos(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, sIdPaisNacionalidad)

CREATE NONCLUSTERED INDEX IX_tmp_simperuanos_sNombre_sPaterno_sMaterno_sSexo_dFechaNacimiento_sIdPaisNacimiento
    ON dbo.#tmp_simperuanos(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, sIdPaisNacimiento)

/*»
	→ 1. Criterios totalmente iguales: APELLIDOS | NOMBRE  | SEXO | NACIONALIDAD | FECHA DE NACIMIENTO ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_1
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_1
FROM (

	SELECT 
		[nContarMulti] = COUNT(1)
	FROM #tmp_simperuanos e
	GROUP BY
		e.sNombre, e.sPaterno, e.sMaterno, e.sSexo, e.dFechaNacimiento, e.sIdPaisNacionalidad
	HAVING
		COUNT(1) >= 2 

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_1 tmp ORDER BY tmp.nContarMulti 

-- 1.2: Movimientos migratorios: ...
DROP TABLE IF EXISTS #tmp_2multiplicidad_mm
;WITH cte_2multiplicidad AS ( -- 93,984

	SELECT e2.* FROM (

		SELECT 
			e.*,
			[nContar_e] = COUNT(e.uIdPersona) OVER (
														PARTITION BY e.sNombre, e.sPaterno, e.sMaterno, e.sSexo, e.dFechaNacimiento, e.sIdPaisNacionalidad
														ORDER BY e.sNombre, e.sPaterno, e.sMaterno, e.sSexo, e.dFechaNacimiento, e.sIdPaisNacionalidad
													)
		FROM #tmp_simperuanos e

	) e2
	WHERE
		e2.nContar_e = 2

), cte_2multiplicidad_mm AS (

	SELECT m2_m.* FROM (
	
		SELECT 
			m2.*,
			[sUltimoMovMigra] = smm.sTipo,
			[nContarMovMigra] = ROW_NUMBER() OVER (PARTITION BY m2.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		RIGHT JOIN cte_2multiplicidad m2 ON smm.uIdPersona = m2.uIdPersona

	) m2_m
	WHERE
		m2_m.nContarMovMigra = 1

) SELECT * INTO #tmp_2multiplicidad_mm FROM cte_2multiplicidad_mm

-- Index 
CREATE INDEX IX_tmp_2multiplicidad_mm_uIdPersona
    ON dbo.#tmp_2multiplicidad_mm(uIdPersona)


-- 1.3: ...
DROP TABLE IF EXISTS #tmp_2multiplicidad_mm_tramites
SELECT TOP 0 * INTO #tmp_2multiplicidad_mm_tramites FROM #tmp_2multiplicidad_mm

ALTER TABLE #tmp_2multiplicidad_mm_tramites
	ADD sTramites NVARCHAR(MAX) NULL

DECLARE @uId AS NVARCHAR(MAX)
DECLARE Multiplicidad CURSOR FOR SELECT m2.uIdPersona FROM #tmp_2multiplicidad_mm m2

OPEN Multiplicidad

FETCH NEXT FROM Multiplicidad INTO @uId

WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE @tramites NVARCHAR(MAX) = ''

	-- 1
	SELECT 
		@tramites = @tramites + stt.sDescripcion + ', ' 
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	WHERE
		st.uIdPersona = @uId
	 
	-- 2
	INSERT INTO #tmp_2multiplicidad_mm_tramites
		SELECT 
			m2.*,
			@tramites
		FROM #tmp_2multiplicidad_mm m2
		WHERE m2.uIdPersona = @uId

	FETCH NEXT FROM Multiplicidad INTO @uId
END

CLOSE Multiplicidad
DEALLOCATE Multiplicidad

-- Test ...
SELECT TOP 1000000 * FROM SimCarnetExtranjeria sce ORDER BY sce.dFechaEmision ASC
SELECT * FROM #tmp_2multiplicidad_mm
SELECT * FROM #tmp_2multiplicidad_mm_tramites e
ORDER BY 
	e.sNombre, e.sPaterno, e.sMaterno, e.sSexo, e.dFechaNacimiento, e.sIdPaisNacionalidad
--===============================================================================================================================================*/


/*»
	→ 2. Criterios totalmente iguales: APELLIDOS | NOMBRE  | SEXO | FECHA DE NACIMIENTO | NACIMIENTO ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_2
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_2
FROM (

	SELECT 
		[nContarMulti] = COUNT(1)
	FROM #tmp_simperuanos e
	GROUP BY
		e.sNombre, e.sPaterno, e.sMaterno, e.sSexo, e.dFechaNacimiento, e.sIdPaisNacimiento
	HAVING
		COUNT(1) >= 2 

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_2 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 3. Criterios totalmente iguales: APELLIDOS | NOMBRE  | SEXO(Dif) | FECHA DE NACIMIENTO | NACIONALIDAD ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_3
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_3
FROM (

	SELECT 
		[nContarMulti] = COUNT(1) 
	FROM (

		SELECT 
			e.*	
		FROM #tmp_simperuanos e
		JOIN #tmp_simperuanos ee ON e.sNombre = ee.sNombre
									  AND e.sPaterno = ee.sPaterno
									  AND e.sSexo != ee.sSexo 
									  AND e.sMaterno = ee.sMaterno
									  AND e.dFechaNacimiento = ee.dFechaNacimiento
									  AND e.sIdPaisNacionalidad = ee.sIdPaisNacionalidad

	) e2
	GROUP BY
		e2.sNombre, e2.sPaterno, e2.sMaterno, e2.dFechaNacimiento, e2.sIdPaisNacionalidad
	HAVING
		COUNT(1) >= 2

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_3 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 4. Criterios totalmente iguales: APELLIDOS | NOMBRE  | SEXO(Dif) | FECHA DE NACIMIENTO | NACIMIENTO ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_4
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_4
FROM (

	SELECT 
		[nContarMulti] = COUNT(1) 
	FROM (

		SELECT 
			e.*	
		FROM #tmp_simperuanos e
		JOIN #tmp_simperuanos ee ON e.sNombre = ee.sNombre
									  AND e.sPaterno = ee.sPaterno
									  AND e.sMaterno = ee.sMaterno
									  AND e.sSexo != ee.sSexo 
									  AND e.dFechaNacimiento = ee.dFechaNacimiento
									  AND e.sIdPaisNacimiento = ee.sIdPaisNacimiento

	) e2
	GROUP BY
		e2.sNombre, e2.sPaterno, e2.sMaterno, e2.dFechaNacimiento, e2.sIdPaisNacimiento
	HAVING
		COUNT(1) >= 2

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_4 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 5. Criterios totalmente iguales: APELLIDOS | NOMBRE(Dif)  | SEXO | FECHA DE NACIMIENTO | NACIONALIDAD ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_5
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_5
FROM (

	SELECT 
		[nContarMulti] = COUNT(1) 
	FROM (

		SELECT 
			e.*	
		FROM #tmp_simperuanos e
		JOIN #tmp_simperuanos ee ON LEN(e.sNombre) != LEN(ee.sNombre)
									  AND (e.sNombre LIKE '%' + ee.sNombre + '%' OR ee.sNombre LIKE '%' + e.sNombre + '%')
									  AND e.sPaterno = ee.sPaterno
									  AND e.sMaterno = ee.sMaterno
									  AND e.sSexo = ee.sSexo 
									  AND e.dFechaNacimiento = ee.dFechaNacimiento
									  AND e.sIdPaisNacionalidad = ee.sIdPaisNacionalidad

	) e2
	GROUP BY
		e2.sPaterno, e2.sMaterno, e2.sSexo, e2.dFechaNacimiento, e2.sIdPaisNacionalidad
	HAVING
		COUNT(1) >= 2

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_5 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 6. Criterios totalmente iguales: APELLIDOS(Dif) | NOMBRE | SEXO | FECHA DE NACIMIENTO | NACIONALIDAD ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_6
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_6
FROM (

	SELECT 
		[nContarMulti] = COUNT(1) 
	FROM (

		SELECT 
			e.*	
		FROM #tmp_simextranjero e
		JOIN #tmp_simextranjero ee ON e.sNombre = ee.sNombre
									  AND (LEN(e.sPaterno) != LEN(ee.sPaterno) OR LEN(e.sMaterno) != LEN(ee.sMaterno))
									  AND (e.sPaterno LIKE '%' + ee.sPaterno + '%' OR ee.sPaterno LIKE '%' + e.sPaterno + '%')
									  AND (e.sMaterno LIKE '%' + ee.sMaterno + '%' OR ee.sMaterno LIKE '%' + e.sMaterno + '%')
									  AND e.sSexo = ee.sSexo 
									  AND e.dFechaNacimiento = ee.dFechaNacimiento
									  AND e.sIdPaisNacionalidad = ee.sIdPaisNacionalidad

	) e2
	GROUP BY
		e2.sNombre, e2.sSexo, e2.dFechaNacimiento, e2.sIdPaisNacionalidad
	HAVING
		COUNT(1) >= 2

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_6 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 9. Criterios totalmente iguales: APELLIDOS | NOMBRE | SEXO | FECHA DE NACIMIENTO(Dif) | NACIONALIDAD ...
===============================================================================================================================================*/

DROP TABLE IF EXISTS #tmp_9
SELECT 
	m_e.nContarMulti,
	[nTotalPersonas] = COUNT(1)
	INTO #tmp_9
FROM (

	SELECT 
		[nContarMulti] = COUNT(1) 
	FROM (

		SELECT 
			e.*	
		FROM #tmp_simextranjero e
		JOIN #tmp_simextranjero ee ON e.sNombre = ee.sNombre
									  AND e.sPaterno = ee.sPaterno
									  AND e.sMaterno = ee.sMaterno
									  AND e.sSexo = ee.sSexo 
									  AND (
											(DAY(e.dFechaNacimiento) != DAY(ee.dFechaNacimiento) AND MONTH(e.dFechaNacimiento) = MONTH(ee.dFechaNacimiento) AND YEAR(e.dFechaNacimiento) = YEAR(ee.dFechaNacimiento))
											OR
											(DAY(e.dFechaNacimiento) = DAY(ee.dFechaNacimiento) AND MONTH(e.dFechaNacimiento) != MONTH(ee.dFechaNacimiento) AND YEAR(e.dFechaNacimiento) = YEAR(ee.dFechaNacimiento))
											OR
											(DAY(e.dFechaNacimiento) = DAY(ee.dFechaNacimiento) AND MONTH(e.dFechaNacimiento) = MONTH(ee.dFechaNacimiento) AND YEAR(e.dFechaNacimiento) != YEAR(ee.dFechaNacimiento))
										  )

									  AND e.sIdPaisNacionalidad = ee.sIdPaisNacionalidad

	) e2
	GROUP BY
		e2.sNombre, e2.sSexo, e2.dFechaNacimiento, e2.sIdPaisNacionalidad
	HAVING
		COUNT(1) >= 2

) m_e
GROUP BY
	m_e.nContarMulti

-- Test ...
SELECT * FROM #tmp_9 tmp ORDER BY tmp.nContarMulti 
--===============================================================================================================================================*/

/*»
	→ 11. Total de uId's extranjeros ...
===============================================================================================================================================*/
SELECT [nTotal_uIdExtranjeros] = COUNT(1) FROM #tmp_simextranjero
--===============================================================================================================================================*/

/*»
	→ 12. M´doulo origen de uId's extranjeros ...
===============================================================================================================================================*/
SELECT	
	[sIdModuloOrigen] = sm.sIdModulo,
	[nTotal] = COUNT(1)
FROM #tmp_simextranjero e
LEFT JOIN SimSesion ss ON e.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
GROUP BY
	sm.sIdModulo
ORDER BY
	[nTotal] DESC
--===============================================================================================================================================*/

/*»
	→ 12. Afluencia de extranjeros ...
===============================================================================================================================================*/

-- 12.1: Afluencia ...
SELECT * FROM (

	SELECT 
		[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
		[nTotalIngresos] = COUNT(1)
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND (smm.sIdPaisNacionalidad NOT IN ('NNN', 'PER', '') AND smm.sIdPaisNacionalidad IS NOT NULL)
		AND smm.sTipo = 'E'
		-- AND (smm.sIdPaisMov NOT IN ('PER', 'NNN', '') AND smm.sIdPaisMov IS NOT NULL)
		AND smm.sIdPaisMov != 'PER'
		AND smm.bTemporal = 0
		-- AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
		AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2023-09-04 23:59:59.999'
	GROUP BY
		DATEPART(YYYY, smm.dFechaControl)

) mm_e
PIVOT (
	SUM(nTotalIngresos) FOR nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv

-- 12.2: Extranjeros por control migratorio ...
SELECT * FROM (

	SELECT 
		mm2.[nAñoControl],
		[nTotalIngresos] = COUNT(1)
	FROM (
	
		SELECT 
			smm.uIdPersona,
			[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		WHERE
			smm.bAnulado = 0
			AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
			-- AND (smm.sIdPaisNacimiento NOT IN ('NNN', 'PER', '') AND smm.sIdPaisNacimiento IS NOT NULL)
			AND (smm.sIdPaisNacionalidad NOT IN ('NNN', 'PER', '') OR smm.sIdPaisNacionalidad IS NOT NULL)
			AND smm.sTipo = 'E'
			AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	
	) mm2
	WHERE
		mm2.nFila_mm = 1
	GROUP BY
		mm2.[nAñoControl]

) mm_e
PIVOT (
	SUM(nTotalIngresos) FOR nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv

-- 12.3: 20 ...
SELECT * FROM (

	SELECT 
		mm2.[nAñoControl],
		[nTotalIngresos] = COUNT(1)
	FROM (
	
		SELECT 
			smm.uIdPersona,
			[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		WHERE
			smm.bAnulado = 0
			AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
			AND (smm.sIdPaisNacionalidad NOT IN ('NNN', 'PER', '') OR smm.sIdPaisNacionalidad IS NOT NULL)
			AND smm.sTipo = 'E'
			-- AND smm.dFechaControl <= '2015-12-31 23:59:59.999'
			AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	
	) mm2
	WHERE
		mm2.nFila_mm = 1
	GROUP BY
		mm2.[nAñoControl]

) mm_e
PIVOT (
	SUM(nTotalIngresos) FOR nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv




--===============================================================================================================================================*/

/*»
	→ 13. Total de CPP(A, P) ...
===============================================================================================================================================*/

SELECT pv.* FROM (

	SELECT 
		[nAñoTramite] = DATEPART(YYYY, st.dFechaHoraReg),
		[sTramite] = stt.sDescripcion,
		sti.sEstadoActual,
		st.sNumeroTramite
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	WHERE
		st.bCancelado = 0
		AND sti.sEstadoActual IN ('A', 'P')
		AND st.nIdTipoTramite IN (113, 126)

) t
PIVOT(
	COUNT(t.sNumeroTramite) FOR t.[nAñoTramite] IN ([2021], [2022], [2023])
) pv
--===============================================================================================================================================*/

/*»
	→ 14. C.E. Emitidos ...
===============================================================================================================================================*/

-- 62 | INSCR.REG.CENTRAL EXTRANJERÍA
SELECT COUNT(1) FROM SimTramite st WHERE st.nIdTipoTramite = 62

-- Emitidos ...
SELECT 
	[sCarnetExtranjeria] = 'Emitidos',
	COUNT(1)
FROM SimCarnetExtranjeria sce 
WHERE
	sce.bAnulado = 0

-- Vigentes
SELECT 
	[sCarnetExtranjeria] = 'Vigentes',
	COUNT(1)
FROM SimCarnetExtranjeria sce 
WHERE
	sce.bAnulado = 0
	AND sce.dFechaCaducidad IS NOT NULL
	AND DATEDIFF(DD, GETDATE(), sce.dFechaCaducidad) > 0 -- Vigentes

-- Test ...
SELECT DATEDIFF(DD, GETDATE(), '2023-09-01')
--===============================================================================================================================================*/

-- 104 | ENTREGA DE CARNÉ DE EXTRANJERÍA
SELECT 
	* 
FROM SimTipoTramite stt
WHERE 
	stt.sDescripcion LIKE '%extr%'




SELECT 
	TOP 10
	smm.*
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	-- AND (smm.sIdPaisNacionalidad NOT IN ('NNN', 'PER', '') AND smm.sIdPaisNacionalidad IS NOT NULL)
	AND smm.sIdPaisNacimiento = 'PER'
	AND (smm.sIdPaisNacionalidad IN ('NNN', '') OR smm.sIdPaisNacionalidad IS NULL)
	-- AND smm.sTipo = 'E'
	-- AND (smm.sIdPaisMov NOT IN ('PER', 'NNN', '') AND smm.sIdPaisMov IS NOT NULL)
	-- AND smm.sIdPaisMov != 'PER'
	AND smm.bTemporal = 0
	-- AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	-- AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2023-09-04 23:59:59.999'



SELECT COUNT(1) FROM SimDocPersona -- 57,260,154
SELECT COUNT(1) FROM SimPersona -- 42375169


SELECT TOP 10 sdp.* FROM SimDocPersona sdp
ORDER BY
	sdp.dFechaHoraAud DESC

-- Base 1: Control Migratorio no tienen Nacionalidad ..

-- 1
DROP TABLE IF EXISTS #tmp_mm_nacionalidadNNN
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	smm.sIdPaisNacionalidad,
	smm.sIdDocumento,
	smm.sNumeroDoc,
	smm.sIdMovMigratorio,
	smm.uIdPersona
	INTO #tmp_mm_nacionalidadNNN
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND (smm.sIdPaisNacionalidad IN ('NNN', '') OR smm.sIdPaisNacionalidad IS NULL)
	AND smm.sIdPaisNacimiento = 'PER'

-- Index ...
CREATE INDEX IX_tmp_mm_nacionalidadNNN_uIdPersona
    ON dbo.#tmp_mm_nacionalidadNNN(uIdPersona)


-- 2
SELECT * FROM (

	SELECT 
		*,
		[sIdPaisNacionalidad_] = CASE
										WHEN (
													SELECT sper.sIdPaisNacionalidad FROM SimPersona sper 
													WHERE 
														sper.uIdPersona = mm.uIdPersona
											 ) NOT IN ('NNN', '') THEN
											 (
												 SELECT sper.sIdPaisNacionalidad FROM SimPersona sper 
														WHERE 
															sper.uIdPersona = mm.uIdPersona
											 )
										ELSE
											(
												IIF(mm.sIdDocumento = 'DNI' AND LEN(mm.sNumeroDoc) = 8, 'PER', mm.sIdPaisNacionalidad)
											)
								 END
	FROM #tmp_mm_nacionalidadNNN mm

) mm2
WHERE
	mm2.sIdPaisNacionalidad_ = 'NNN'

SELECT 687 - 466

SELECT COUNT(1) FROM #tmp_mm_nacionalidadNNN

SimExtranjero
SimTramite
SimTramiteInm
SimCarnetExtranjeria

/*
	smm.sNombres,
	Apellido 1	
	Apellido 2	
	Sexo	
	Fecha de Nacimiento	
	Nacionalidad
	Id Mov Migratorio	
	Id Persona	
	Tipo de documento	
	Número de documento
*/