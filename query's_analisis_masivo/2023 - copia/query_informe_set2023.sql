USE SIM
GO

/*░
-- 1. Base de datos de Control Migratorio del Sistema Integrado de Migraciones de ciudadanos peruanos que no tienen nacionalidad (NNN).
==========================================================================================================================================================*/
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	smm.sIdMovMigratorio,
	smm.uIdPersona,
	[sCalidad_CM] = scm.sDescripcion,
	[sIdDocumento_CM] = smm.sIdDocumento,
	[sNumeroDoc_CM] = CONCAT('''', smm.sNumeroDoc),
	[sIdPaisNacionalidad_CM] = smm.sIdPaisNacionalidad,
	[sIdPaisNacionalidad_P] = sper.sIdPaisNacionalidad
FROM SimMovMigra smm 
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE
	sper.bActivo = 1
	AND sper.sIdPaisNacionalidad = 'PER'
	AND smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.sIdDocumento IN ('DNI', 'PAS')
	AND smm.nIdCalidad = 21 -- 21 | PERUANO                                  
	AND (smm.sIdPaisNacionalidad IN ('NNN', '') OR smm.sIdPaisNacionalidad IS NULL)
ORDER BY 
	smm.dFechaControl DESC
--==========================================================================================================================================================*/

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

