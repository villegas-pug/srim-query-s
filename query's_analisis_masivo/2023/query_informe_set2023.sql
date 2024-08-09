USE SIM
GO

/*░
-- 1. Base de datos de Control Migratorio del Sistema Integrado de Migraciones de ciudadanos peruanos que no registran nacionalidad (NNN).
==========================================================================================================================================================*/

-- 1.1.1 `tmp`

SELECT 
	pe.sNombre,
	pe.sPaterno,
	pe.sMaterno,
	pe.sSexo,
	pe.dFechaNacimiento,
	mm.sIdMovMigratorio,
	mm.uIdPersona,

	-- Aux
	[Documento(SimMovMigra)] = mm.sIdDocumento,
	[Numero Doc(SimMovMigra)] = CONCAT('''', mm.sNumeroDoc),
	[Pais Nacionalidad(SimMovMigra)] = mm.sIdPaisNacionalidad,
	[Pais Nacionalidad(SimPersona)] = pe.sIdPaisNacionalidad,
	
	[Total Registros(SimMovMigra)] = COUNT(1) OVER (PARTITION BY mm.uIdPersona), -- >=2

	[Nacionalidades(SimMovMigra)] = ( -- Nacionalidades registradas
													SELECT 
														[Nacionalidad] = mm2.sIdPaisNacionalidad,
														[Total] = COUNT(1)
													FROM SimMovMigra mm2
													WHERE
														mm2.bAnulado = 0
														AND mm2.bTemporal = 0
														AND mm2.uIdPersona = pe.uIdPersona
													GROUP BY
														mm2.sIdPaisNacionalidad
													ORDER BY 2 DESC
													FOR XML PATH('')
											),
	[Nacionalidad Recurrente(SimMovMigra)] = (
																SELECT 
																	TOP 1
																	mm2.sIdPaisNacionalidad
																FROM SimMovMigra mm2
																WHERE
																	mm2.bAnulado = 0
																	AND mm2.bTemporal = 0
																	AND mm2.uIdPersona = pe.uIdPersona
																GROUP BY
																	mm2.sIdPaisNacionalidad
																ORDER BY COUNT(1) DESC
													)


FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
	pe.bActivo = 1
	AND mm.bAnulado = 0
	AND mm.bTemporal = 0
	AND pe.sIdPaisNacionalidad != 'NNN'
	AND (mm.sIdPaisNacionalidad = 'NNN' AND pe.sIdPaisNacionalidad != 'NNN')
	-- AND smm.sIdDocumento IN ('DNI', 'PAS')
	-- AND smm.nIdCalidad = 21 -- 21 | PERUANO


-- 1.2. Método-2

-- 1.2.1: `tmp's`

-- SimMovMigra ↔ SimPersona
DROP TABLE IF EXISTS #tmp_pe_mm_nnn
SELECT 
	mm.sIdMovMigratorio,
	mm.uIdPersona,
	[sIdPaisNacionalidad(SimMovMigra)] = mm.sIdPaisNacionalidad,
	[sIdPaisNacionalidad(SimPersona)] = pe.sIdPaisNacionalidad
	INTO #tmp_pe_mm_nnn
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
	pe.bActivo = 1
	AND mm.bAnulado = 0
	AND mm.bTemporal = 0
	AND (mm.sIdPaisNacionalidad = 'NNN' AND pe.sIdPaisNacionalidad != 'NNN')


DROP TABLE IF EXISTS #tmp_mm
SELECT 
	mm.sIdMovMigratorio,
	mm.uIdPersona,
	mm.sIdPaisNacionalidad
	INTO #tmp_mm
FROM SimMovMigra mm
WHERE
	mm.bAnulado = 0
	AND mm.bTemporal = 0
	AND mm.uIdPersona IN ( SELECT DISTINCT n.uIdPersona FROM #tmp_pe_mm_nnn n) 

CREATE NONCLUSTERED INDEX ix_tmp_mm_uid 
	ON #tmp_mm(uIdPersona)

-- 1.2.2: ...
BEGIN

	-- repositorio:
	DROP TABLE IF EXISTS #tmp_mm_nnn_final
	SELECT 
		TOP 0
		mm.uIdPersona,
		mm.sIdMovMigratorio,
		[sNacionalidades(SimMovMigra)] = REPLICATE('', 5000),
		[sIdPaisNacionalidad(SimPersona)] = REPLICATE('', 3),
		[sEstado] = REPLICATE('', 55)
		INTO #tmp_mm_nnn_final
	FROM SimMovMigra mm

	-- Copia: `#tmp_pe_mm_nnn`
	DROP TABLE IF EXISTS #tmp_pe_mm_nnn_bak
	SELECT * INTO #tmp_pe_mm_nnn_bak FROM #tmp_pe_mm_nnn


	-- » Evaluación de casos atipicos ...
	WHILE (EXISTS(SELECT TOP 1 1 FROM #tmp_pe_mm_nnn_bak))
	BEGIN

		-- Dep's
		DECLARE @uIdNNN UNIQUEIDENTIFIER
		DECLARE @sIdMovMigraNNN CHAR(14)
		DECLARE @sIdPaisNacPer CHAR(3)

		-- Único registro inconsistente para evaludar ...
		SELECT 
			TOP 1
			@uIdNNN = r.uIdPersona,
			@sIdMovMigraNNN = r.sIdMovMigratorio,
			@sIdPaisNacPer = r.[sIdPaisNacionalidad(SimPersona)]
		FROM #tmp_pe_mm_nnn_bak r
		ORDER BY r.sIdMovMigratorio ASC

		-- Nacionalidades concurrentes en Movimiento Migratorios ...
		DECLARE @tblNacConcurrMM TABLE (sIdPaisNacionalidad CHAR(3), nTotal INT) -- tmp
		DECLARE @nacsConcurrMM VARCHAR(MAX) = ''
		DECLARE @nacConcurrMM CHAR(3)
		DECLARE @totalMovMigra INT = (SELECT COUNT(1) FROM #tmp_mm mm WHERE mm.uIdPersona = @uIdNNN)
		DECLARE @totalNacConcurrMM INT

		-- Si registra 1 movimiento migratorio, pasa a siguiente iteración ...
		IF (@totalMovMigra = 1) GOTO clean_up

		-- Nacionalidades concurrentes en MovMigra ...
		INSERT INTO @tblNacConcurrMM
			SELECT 
				mm.sIdPaisNacionalidad,
				[nTotal] = COUNT(1)
			FROM #tmp_mm mm
			WHERE mm.uIdPersona = @uIdNNN
			GROUP BY mm.sIdPaisNacionalidad

		SELECT 
			@nacsConcurrMM += CONCAT(c.sIdPaisNacionalidad, ': ', c.nTotal, ', ', CHAR(10))
		FROM @tblNacConcurrMM c
		ORDER BY c.nTotal DESC

		SET @nacConcurrMM = (SELECT TOP 1 c.sIdPaisNacionalidad FROM @tblNacConcurrMM c ORDER BY c.nTotal DESC)
		SET @totalNacConcurrMM = (SELECT COUNT(1) FROM @tblNacConcurrMM)

		-- CA-01: Si registra 2 movimientos migratorios. → E: `Para analizar`
		IF (@totalMovMigra = 2) GOTO TO_ANALISIS

		-- CA-02: Nacionalidad más registrada en `SimMovMigra` es `NNN`. → E: `Para análisis`
		IF (@nacConcurrMM = 'NNN') GOTO TO_ANALISIS

		-- CA-03: Nacionalidades concurrentes en `SimMovMigra` es mayor o igual a 3. → E: `Para análisis`
		IF (@totalNacConcurrMM >= 3) GOTO TO_ANALISIS

		-- CA-03: Nacionalidad más registrada en `SimMovMigra` es diferente a nacionalidad de `SimPersona`. → E: `Para análisis`
		IF (@nacConcurrMM != @sIdPaisNacPer) GOTO TO_ANALISIS

		-- CA-04: Nacionalidad más registrada en `SimMovMigra` es igual a nacionalidad de `SimPersona`. → E: `Para levantamiento`
		IF (@nacConcurrMM = @sIdPaisNacPer)
			BEGIN
				INSERT INTO #tmp_mm_nnn_final
					VALUES(
						@uIdNNN,
						@sIdMovMigraNNN,
						@nacsConcurrMM,
						@sIdPaisNacPer,
						'Para levantamiento'
					)

				GOTO CLEAN_UP
			END

		-- Si, no ocurre ninguno de los casos atípicos:
		GOTO CLEAN_UP


		TO_ANALISIS:
			INSERT INTO #tmp_mm_nnn_final
					VALUES(
						@uIdNNN,
						@sIdMovMigraNNN,
						@nacsConcurrMM,
						@sIdPaisNacPer,
						'Para análisis'
					)

		CLEAN_UP:
			DELETE FROM @tblNacConcurrMM
			DELETE FROM #tmp_pe_mm_nnn_bak WHERE sIdMovMigratorio = @sIdMovMigraNNN

	END

END


-- Test
SELECT COUNT(f.sIdMovMigratorio) FROM #tmp_mm_nnn_final f -- 12,074
SELECT COUNT(DISTINCT f.sIdMovMigratorio) FROM #tmp_mm_nnn_final f -- 12,074

SELECT * FROM #tmp_mm_nnn_final f
WHERE f.sEstado = 'Para análisis'

-- WHERE f.uIdPersona = '8f735dac-7c7d-46ed-bf6c-a6daecfd5501'

SELECT COUNT(1) FROM SimMovMigra f
WHERE 
	f.bAnulado = 0
	AND f.bTemporal = 0
	AND f.uIdPersona = '8f735dac-7c7d-46ed-bf6c-a6daecfd5501'



-- =========================================================================================================================================================

/*░
-- 2. Base de datos Control Migratorio del sitema integrado de migraciones de peruanos que contiene una letra en su número de DNI.
==========================================================================================================================================================*/

-- 2.1: Aux 1 ...
CREATE OR ALTER FUNCTION ufn_getDNIByUIdPersona
(
    @uIdPersona UNIQUEIDENTIFIER
)
RETURNS VARCHAR(25)
AS
BEGIN

	-- Dep's ...
	DECLARE @numeroDoc CHAR(8)

	-- SimDocPersona ...
	SET @numeroDoc = (
						SELECT TOP 1 sdp.sNumero FROM SimDocPersona sdp
						WHERE 
							sdp.bActivo = 1
							AND sdp.uIdPersona = @uIdPersona
							AND sdp.sIdDocumento = 'DNI'
							AND LEN(RTRIM(LTRIM(sdp.sNumero))) = 8
							AND sdp.sNumero NOT LIKE '%[a-zA-Z]%'
					 )

	IF @numeroDoc IS NOT NULL
	BEGIN
		RETURN @numeroDoc
	END

	-- SimPersona ...
	SET @numeroDoc = (
						SELECT TOP 1 sper.sNumDocIdentidad FROM SimPersona sper
						WHERE 
							sper.bActivo = 1
							AND sper.sIdDocIdentidad = 'DNI'
							AND sper.uIdPersona = @uIdPersona
					 )

	IF @numeroDoc IS NOT NULL AND LEN(RTRIM(LTRIM(@numeroDoc))) = 8 AND @numeroDoc NOT LIKE '%[a-zA-Z]%'
	BEGIN
		RETURN @numeroDoc
	END


	-- Base Central ...
	SET @numeroDoc = (
						SELECT TOP 1 pas.sNumeroDNI FROM BD_SIRIM.dbo.RimPasaporte pas
						JOIN SimTramite st ON pas.sNumeroTramite = st.sNumeroTramite
						WHERE 
							st.uIdPersona = @uIdPersona
					 )

	IF @numeroDoc IS NOT NULL AND LEN(RTRIM(LTRIM(@numeroDoc))) = 8 AND @numeroDoc NOT LIKE '%[a-zA-Z]%'
	BEGIN
		RETURN @numeroDoc
	END

	RETURN 'CONSULTAR RENIEC'

END

-- Aux 2 ...
CREATE OR ALTER FUNCTION dbo.ufn_compareByNumeroDoc
(
    @numeroDNI_Err VARCHAR(25),
	@numeroDNI_Valid VARCHAR(25)
)
RETURNS VARCHAR(100)
AS
BEGIN
	
	-- Longitud ...
	-- IF (LEN(LTRIM(RTRIM(@numeroDNI_Err))) != LEN(LTRIM(RTRIM(@numeroDNI_Valid)))) RETURN 0

	-- Aproximación ...
	-- Dep's ...
	DECLARE @iCharErr INT,
			@numeroDNI_Err_Copy VARCHAR(25),
			@numeroDNI_Valid_Copy VARCHAR(25)

	SET @numeroDNI_Err_Copy = LTRIM(RTRIM(@numeroDNI_Err))
	SET @numeroDNI_Valid_Copy = LTRIM(RTRIM(@numeroDNI_Valid))
	SET @iCharErr = PATINDEX('%[a-zA-Z]%', @numeroDNI_Err_Copy)
	WHILE (@iCharErr > 0)
	BEGIN
		
		SET @numeroDNI_Err_Copy = STUFF(@numeroDNI_Err_Copy, @iCharErr, 1, '')
		SET @numeroDNI_Valid_Copy = STUFF(@numeroDNI_Valid_Copy, @iCharErr, 1, '')

		SET @iCharErr = PATINDEX('%[a-zA-Z]%', @numeroDNI_Err_Copy)
	END

	IF (@numeroDNI_Valid_Copy IS NULL) RETURN 0
	IF (LEN(@numeroDNI_Err_Copy) = 0) RETURN 0
	IF (@numeroDNI_Err_Copy != @numeroDNI_Valid_Copy) RETURN 0

	RETURN 1
END

-- 2.2 ...
SELECT 
	cm.*,
	[sNumDocumento_CM2] = CONCAT('''', cm.sNumDocumento_CM), 
	[sNumDocumento_BCP2] = CONCAT('''', cm.sNumDocumento_BCP)
FROM (
	
	SELECT 
		sper.sNombre,
		sper.sPaterno,
		sper.sMaterno,
		sper.sSexo,
		sper.dFechaNacimiento,
		sper.sIdPaisNacionalidad,
		smm.sIdMovMigratorio,
		smm.uIdPersona,
		[sDocumento_CM] = smm.sIdDocumento,
		[sNumDocumento_CM] = smm.sNumeroDoc,
		[sNumDocumento_BCP] = dbo.ufn_getDNIByUIdPersona(smm.uIdPersona)
	FROM SimMovMigra smm 
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	JOIN SimUsuario u ON smm.nIdOperadorDigita = u.nIdOperador
	WHERE
		smm.bAnulado = 0
		AND smm.bTemporal = 0
		AND smm.sIdPaisNacionalidad = 'PER'
		AND (smm.sIdDocumento = 'DNI' AND smm.sNumeroDoc LIKE '%[a-zA-Z]%')

) cm
WHERE
	cm.sNumDocumento_BCP != 'CONSULTAR RENIEC'
	AND dbo.ufn_compareByNumeroDoc(cm.[sNumDocumento_CM], cm.[sNumDocumento_BCP]) = 1

-- Opeador digita:
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM SimMovMigra smm 
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimUsuario u ON smm.nIdOperadorDigita = u.nIdOperador
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	AND smm.sIdPaisNacionalidad = 'PER'
	AND (smm.sIdDocumento = 'DNI' AND smm.sNumeroDoc LIKE '%[^0-9]%')
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

--==========================================================================================================================================================*/


/*░
-- 3. Base de datos del Sistema Integrado de Migraciones de peruanos que contienen letras en su DNI.
==========================================================================================================================================================*/
SELECT 
	p2.*,
	[sNumDocIdentidad2] = CONCAT('''', p2.sNumDocIdentidad),
	[sNumDocIdentidad_BCP2] = CONCAT('''', p2.sNumDocIdentidad_BCP)
FROM (

	SELECT 
		sper.sNombre,
		sper.sPaterno,
		sper.sMaterno,
		sper.sSexo,
		sper.dFechaNacimiento,
		sper.sIdPaisNacionalidad,
		sper.uIdPersona,
		sper.sIdDocIdentidad,
		[sNumDocIdentidad] = sper.sNumDocIdentidad,
		[sNumDocIdentidad_BCP] = dbo.ufn_getDNIByUIdPersona(sper.uIdPersona)
	FROM SimPersona sper
	WHERE
		sper.bActivo = 1
		AND sper.sIdPaisNacionalidad = 'PER'
		AND (sper.sIdDocIdentidad IN ('DNI') AND sper.sNumDocIdentidad LIKE '%[a-zA-Z]%')

) p2
WHERE
	p2.sNumDocIdentidad_BCP != 'CONSULTAR RENIEC'
	AND dbo.ufn_compareByNumeroDoc(p2.[sNumDocIdentidad], p2.[sNumDocIdentidad_BCP]) = 1
--==========================================================================================================================================================*/


/*░
-- 4. Base de datos de la Control Migratorio de ciudadanos nacionales que tienen registros idénticos en apellidos, nombres, fecha de nacimiento, sexo y nacionalidad.
=========================================================================================================================================================================*/

-- 4.1: Aux ...
DROP TABLE IF EXISTS #tmp_SimPeruano
SELECT sper.* INTO #tmp_SimPeruano
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND (sper.sIdDocIdentidad IS NOT NULL AND sper.sNumDocIdentidad IS NOT NULL)
	AND sper.sIdPaisNacionalidad = 'PER'

-- 4.2: Movimientos Migratorios ...
DROP TABLE IF EXISTS #tmp_SimPeruano_mm
SELECT 
	sper2.*
	INTO #tmp_SimPeruano_mm
FROM (

	SELECT 
		sper.*,
		[nContar_MovMig] = (
								SELECT COUNT(1) FROM SimMovMigra smm
								WHERE 
									smm.uIdPersona = sper.uIdPersona
							)
	FROM SimPersona sper
	WHERE
		sper.bActivo = 1
		AND (sper.sIdDocIdentidad IS NOT NULL AND sper.sNumDocIdentidad IS NOT NULL)
		AND sper.sIdPaisNacionalidad = 'PER'

) sper2
WHERE
	sper2.nContar_MovMig >= 1

-- 4.2: Generar `sIdPersona` ...
DROP TABLE IF EXISTS #tmp_SimPeruano_mm_sId
SELECT
	[sIdPersona] = (
						CONCAT(
							p.sNombre,
							p.sPaterno,
							p.sMaterno,
							p.sSexo,
							p.sIdDocIdentidad,
							p.sNumDocIdentidad,
							CAST(CAST(p.dFechaNacimiento AS FLOAT) AS INT),
							p.sIdPaisNacionalidad
						)
	),
	p.*
	INTO #tmp_SimPeruano_mm_sId
FROM #tmp_SimPeruano_mm p

UPDATE #tmp_SimPeruano_mm_sId
	SET sIdPersona = REPLACE(sIdPersona, ' ', '')

-- Index ...
CREATE INDEX IX_tmp_SimPeruano_mm_sId
    ON dbo.#tmp_SimPeruano_mm_sId(sIdPersona)

-- 4.3: ...
DROP TABLE IF EXISTS #tmp_SimPeruano_mm_sId_2masregistros
SELECT 
	p2.*
	INTO #tmp_SimPeruano_mm_sId_2masregistros
FROM (

	SELECT 
		p.sIdPersona,
		p.uIdPersona,
		p.sNombre,
		p.sPaterno,
		p.sMaterno,
		p.sSexo,
		p.sIdDocIdentidad,
		[sNumDocIdentidad] = CONCAT('''', p.sNumDocIdentidad),
		p.dFechaNacimiento,
		p.sIdPaisNacionalidad,
		[nContar_SID] = COUNT(p.sIdPersona) OVER (PARTITION BY p.sIdPersona),
		p.nContar_MovMig
	FROM #tmp_SimPeruano_mm_sId p

) p2
WHERE
	p2.nContar_SID >= 2
ORDER BY
	p2.sIdPersona

-- Test ...
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM #tmp_SimPeruano_mm_sId_2masregistros pe
JOIN SimPersona p ON pe.uIdPersona = p.uIdPersona
JOIN SimSesion s ON p.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

EXEC sp_help SimSesion
--=======================================================================================================================================================================*/


/*░
-- 5. Base de datos de la tabla SimPersona de ciudadanos extranjeros, que tienen registros idénticos en apellidos, nombres, fecha de nacimiento, sexo y nacionalidad.
=========================================================================================================================================================================*/

-- 5.1: Aux ...
DROP TABLE IF EXISTS #tmp_SimExtranjero
SELECT sper.* INTO #tmp_SimExtranjero FROM SimPersona sper
WHERE
	sper.bActivo = 1
	-- AND sper.sIdPaisNacionalidad = 'PER'
	AND (sper.sIdDocIdentidad IS NOT NULL AND sper.sNumDocIdentidad IS NOT NULL)
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
							e.sIdDocIdentidad,
							e.sNumDocIdentidad,
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
DROP TABLE IF EXISTS #tmp_SimExtranjero_sId_2masregistros
SELECT 
	e2.*,
	[nContar_Tramites] = (
							SELECT COUNT(1) FROM SimTramite st 
							WHERE 
								st.uIdPersona = e2.uIdPersona
						 ),
	[nContar_MovMig] = (
							SELECT COUNT(1) FROM SimMovMigra smm
							WHERE 
								smm.uIdPersona = e2.uIdPersona
					   )
	INTO #tmp_SimExtranjero_sId_2masregistros
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
	e2.nContar_SID >= 2
ORDER BY
	e2.sIdPersona

-- Test ...
SELECT * FROM #tmp_SimExtranjero_sId_2masregistros sper
ORDER BY
	sper.sIdPersona

--=======================================================================================================================================================================*/

