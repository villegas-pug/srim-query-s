USE SIM
GO

-- INFORME-000163-2023-SRIM-MIGRACIONES

/*░
	→ 1. Registro de control migratorio de peruanos, que contienen letras en el número de pasaporte electrónico ...
======================================================================================================================================================*/

-- Aux function's ...
-- 1: ...
CREATE OR ALTER FUNCTION [dbo].[CountLetters]
(
    @texto NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN

	DECLARE @textoSinLetras NVARCHAR(MAX) = @texto,
			  @letterIndex INT = -1
	
	WHILE(PATINDEX('%[a-zA-Z]%', @textoSinLetras) > 0)
	BEGIN
		SET @letterIndex = PATINDEX('%[a-zA-Z]%', @textoSinLetras)
		SET @textoSinLetras = STUFF(@textoSinLetras, @letterIndex, 1, '')
	END

    RETURN LEN(@texto) - LEN(@textoSinLetras)

END

-- 2: Compara números con letras y sin letras ...
CREATE OR ALTER FUNCTION [dbo].[CompareNumbersThatContainLetters]
(
	@numCorrecto NVARCHAR(MAX),
	@numIncorrecto NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN

	DECLARE @numIncorrectoSinLetras NVARCHAR(MAX) = @numIncorrecto,
			  @numCorrectoSinLetterIndex NVARCHAR(MAX) = @numCorrecto,
			  @letterIndex INT = -1
	
	WHILE(PATINDEX('%[a-zA-Z]%', @numIncorrectoSinLetras) > 0)
	BEGIN
		SET @letterIndex = PATINDEX('%[a-zA-Z]%', @numIncorrectoSinLetras)
		SET @numIncorrectoSinLetras = STUFF(@numIncorrectoSinLetras, @letterIndex, 1, '')
		SET @numCorrectoSinLetterIndex = STUFF(@numCorrectoSinLetterIndex, @letterIndex, 1, '')
	END

    RETURN IIF(@numIncorrectoSinLetras = @numCorrectoSinLetterIndex, 1, 0)

END


-- 1: SimMovMigra PAS-E ...
DROP TABLE IF EXISTS #tmp_pase_err
SELECT 
	smm.sIdMovMigratorio,
	smm.uIdPersona,
	/*smm.sIdDependencia,
	smm.nIdSesion,
	smm.nIdOperadorDigita,
	smm.sIdPaisMov,*/
	smm.sIdDocumento,
	[sNumeroDocIncorrecto] = RTRIM(LTRIM(smm.sNumeroDoc))
	INTO #tmp_pase_err
FROM SimMovMigra smm
WHERE 
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2022-12-31 23:59:59.999'
	AND smm.sIdPaisNacionalidad = 'PER'
	AND smm.sIdDocumento = 'PAS'
	AND LEN(smm.sNumeroDoc) = 9
	AND smm.sNumeroDoc LIKE '1[1-2]%[a-zA-Z]%'

-- Index
CREATE INDEX IX_tmp_pase_err_uIdPersona
   ON dbo.#tmp_pase_err(uIdPersona)

-- 2: Final ...
DROP TABLE IF EXISTS #tmp_pase_err_final
SELECT * INTO #tmp_pase_err_final FROM (

	SELECT 
		sper.sNombre,
		sper.sPaterno,
		sper.sMaterno,
		sper.sSexo,
		sper.dFechaNacimiento,
		sper.sIdPaisNacionalidad,
		pas.*,
		[sNumeroDocCorrecto] = (
									SELECT 
										rpas.sNumeroPasaporte
									FROM BD_SIRIM.dbo.RimPasaporte rpas -- Base Central de Pasaportes: Copia en 172.27.0.124; BD_SIRIM.dbo.RimPasaporte
									JOIN SimTramite st ON rpas.sNumeroTramite = st.sNumeroTramite
									WHERE
										st.uIdPersona = pas.uIdPersona
										AND  dbo.CompareNumbersThatContainLetters(rpas.sNumeroPasaporte, pas.sNumeroDocIncorrecto) = 1
								)
	FROM #tmp_pase_err pas
	JOIN SimPersona sper ON pas.uIdPersona = sper.uIdPersona

) pas_f
WHERE
	pas_f.sNumeroDocCorrecto IS NOT NULL

-- Test ...
SELECT COUNT(1) FROM #tmp_pase_err_final pas
SELECT TOP 10 * FROM #tmp_pase_err_final pas
WHERE
	dbo.CountLetters(pas.sNumeroDocIncorrecto) > 2
-- =============================================================================================================================================================== */



/*░
-- 2. Registro de control migratorio de peruanos, que contienen letras en el número de DNI ...
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

   -- 1ra Busqueda: De DNI en SimDocPersona ...
	SET @numeroDoc = (
						SELECT TOP 1 sdp.sNumero FROM SimDocPersona sdp
						WHERE 
							sdp.bActivo = 1
							AND sdp.uIdPersona = @uIdPersona
							AND sdp.sIdDocumento = 'DNI'
							AND LEN(RTRIM(LTRIM(sdp.sNumero))) = 8
							AND sdp.sNumero NOT LIKE '%[a-zA-Z]%'
					 )

   -- Si hay resultado en SimDocPersona, termina ...
	IF @numeroDoc IS NOT NULL
	BEGIN
		RETURN @numeroDoc
	END

	-- 2da Busqueda: De DNI en SimPersona ...
	SET @numeroDoc = (
                        SELECT TOP 1 sper.sNumDocIdentidad FROM SimPersona sper
                        WHERE 
                           sper.bActivo = 1
                           AND sper.sIdDocIdentidad = 'DNI'
                           AND sper.uIdPersona = @uIdPersona
                     )

   -- Si hay resultado en SimDocPersona, termina ...
	IF @numeroDoc IS NOT NULL AND LEN(RTRIM(LTRIM(@numeroDoc))) = 8 AND @numeroDoc NOT LIKE '%[a-zA-Z]%'
	BEGIN
		RETURN @numeroDoc
	END

   -- 3ra Busqueda: De DNI en Base Central de Pasaportes → Copia en 172.27.0.124; BD_SIRIM.dbo.RimPasaporte
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
DROP TABLE IF EXISTS #tmp_mm_dni_with_letters
SELECT 
	cm.*
   INTO #tmp_mm_dni_with_letters
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
		[sNumDocumento_MovMigra] = CONCAT('''', smm.sNumeroDoc),
		[sNumDocumento_SIM] = CONCAT('''', dbo.ufn_getDNIByUIdPersona(smm.uIdPersona))
	FROM SimMovMigra smm 
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	WHERE
		smm.bAnulado = 0
		AND smm.bTemporal = 0
		AND smm.sIdPaisNacionalidad = 'PER'
      AND LEN(smm.sNumeroDoc) = 8
		AND (smm.sIdDocumento = 'DNI' AND smm.sNumeroDoc LIKE '%[a-zA-Z]%')

) cm
WHERE
	cm.sNumDocumento_SIM != 'CONSULTAR RENIEC'
	AND dbo.ufn_compareByNumeroDoc(cm.[sNumDocumento_MovMigra], cm.[sNumDocumento_SIM]) = 1

-- Test ...
SELECT COUNT(1) FROM #tmp_mm_dni_with_letters
SELECT TOP 100 * FROM #tmp_mm_dni_with_letters
-- ============================================================================================================================================================ */