USE SIM
GO

-- Indices en Base central ...
CREATE NONCLUSTERED INDEX IX_RimPasaporte_sNumeroTramite
    ON BD_SIRIM.dbo.RimPasaporte(sNumeroTramite)

CREATE NONCLUSTERED INDEX IX_RimPasaporte_sNumeroPasaporte
    ON BD_SIRIM.dbo.RimPasaporte(sNumeroPasaporte)

/*░
	→ Aux function's ...
==============================================================================================================================*/

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

-- Test ...
SELECT TOP 10 * FROM #tmp_pase_err pas
WHERE dbo.countLetters(pas.sNumeroDocIncorrecto) > 1

-- 2: Compara números. Correcto e incorrecto, el incorrecto contiene letras ...
CREATE OR ALTER FUNCTION [dbo].[CompareNumberContainLetters]
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

-- Test ...
SELECT dbo.CompareNumberContainLetters('5512375123', 'LM1f3LM123')

-- 3: ...
CREATE OR ALTER FUNCTION [dbo].ufn_ExtraeMensajeDeSimAudModPasaporte
(
    @xml XML
)
RETURNS VARCHAR(MAX)
AS
BEGIN

	DECLARE @xmlCopy VARCHAR(MAX) = CONVERT(VARCHAR(MAX), @xml),
		    @flagSearched VARCHAR(15) = 'sMensaje'

	SET @xmlCopy = SUBSTRING(@xmlCopy, CHARINDEX(@flagSearched, @xmlCopy) + LEN(@flagSearched) + 1, LEN(@xmlCopy))
	SET @xmlCopy = SUBSTRING(@xmlCopy, 1, CHARINDEX(@flagSearched, @xmlCopy) - 4)

	RETURN @xmlCopy

END

-- Test ...
DECLARE @xml XML = (SELECT TOP 1 sap.xDataSalida FROM SimAudModPasaporte sap)
SELECT [dbo].ufn_ExtraeMensajeDeSimAudModPasaporte(@xml)

--==============================================================================================================================*/



/*░
	→ 1.  Número de pasaportes de personas nacionales con letras en el control migratorio ...
================================================================================================================================*/

-- Base: 38,374,952
SELECT COUNT(1) FROM SimMovMigra smm
WHERE 
	smm.bAnulado = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2022-12-31 23:59:59.999'
	AND smm.sIdPaisNacionalidad = 'PER'

-- 1: ...
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
									FROM BD_SIRIM.dbo.RimPasaporte rpas
									JOIN SimTramite st ON rpas.sNumeroTramite = st.sNumeroTramite
									WHERE
										st.uIdPersona = pas.uIdPersona
										AND  dbo.CompareNumberContainLetters(rpas.sNumeroPasaporte, pas.sNumeroDocIncorrecto) = 1
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
	dbo.CountLetters(pas.sNumeroDocIncorrecto) > 1
--================================================================================================================================*/


/*░
	→ 2. No registran pais de nacimiento en SimPasaporte ...
================================================================================================================================*/

-- Base: 87,640,867
SELECT COUNT(1) FROM SimMovMigra smm
WHERE 
	smm.bAnulado = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2022-12-31 23:59:59.999'

-- 1: Pasaporte electrónico NULL or NNN en pais nacimiento ...
-- 90 | Expedición de Pasaporte Electrónico
DROP TABLE IF EXISTS #tmp_spas_not_paisnacimiento
SELECT
	st.uIdPersona,
	spas.sNumeroTramite,
	spas.sNombre,
	spas.sPaterno,
	spas.sMaterno,
	spas.sSexo,
	spas.dFechaNacimiento,
	spas.sPasNumero,
	spas.sEstadoActual,
	spas.sIdPaisNacimiento
	INTO #tmp_spas_not_paisnacimiento
FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
WHERE 
	st.bCancelado = 0
	AND st.nIdTipoTramite = 90 -- Expedición de Pasaporte Electrónico
	AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND (spas.sIdPaisNacimiento IS NULL OR spas.sIdPaisNacimiento = 'NNN')

-- Index
CREATE INDEX IX_tmp_spas_not_paisnacimiento_uIdPersona
    ON dbo.#tmp_spas_not_paisnacimiento(uIdPersona)

-- 2: Final ...
SELECT COUNT(1) FROM #tmp_spas_not_paisnacimiento
SELECT * FROM #tmp_spas_not_paisnacimiento
SELECT * FROM (

	SELECT 
		spas.*,
		[sIdPaisNacimiento(SimPersona)] = COALESCE(sper.sIdPaisNacimiento, '-')
	FROM #tmp_spas_not_paisnacimiento spas
	LEFT JOIN SImPersona sper ON spas.uIdPersona = sper.uIdPersona

) spas_f
WHERE
	spas_f.[sIdPaisNacimiento(SimPersona)] != 'NNN' 
	AND spas_f.[sIdPaisNacimiento(SimPersona)] IS NOT NULL 
	AND spas_f.[sIdPaisNacimiento(SimPersona)] != 'PER'


-- Test ...
SELECT TOP 10 * FROM #tmp_spas_not_paisnacimiento
--==============================================================================================================================*/

/*░
	→ 3. Pasaportes electrónicos no migrados a SimPasaporte ...
================================================================================================================================*/
-- Base: 3,954,465
SELECT COUNT(1) FROM BD_SIRIM.dbo.RimPasaporte pase
WHERE
	pase.sEstado = 'ENTREGADA'
	AND pase.sNumeroPasaporte IS NOT NULL

-- 1
-- SELECT TOP 1 * FROM SimAudModPasaporte sap WHERE sap.sProcedimiento = 'usp_RegistroPasaporteSIM_PE'
DROP TABLE IF EXISTS #tmp_pase_nomigrados_simpas
SELECT 
	pase.*
	INTO #tmp_pase_nomigrados_simpas 
FROM BD_SIRIM.dbo.RimPasaporte pase
WHERE
	pase.sEstado = 'ENTREGADA'
	AND pase.sNumeroPasaporte IS NOT NULL
	AND NOT EXISTS (
				SELECT 1 FROM SimPasaporte spas 
				WHERE 
					spas.sPasNumero = pase.sNumeroPasaporte
	)

-- 2: ...
ALTER TABLE [dbo].[SimAudModPasaporte]
	ADD sDataEntrada AS CONVERT(VARCHAR(8000), xDataEntrada)

DROP TABLE IF EXISTS SimAudModPasaporte2
SELECT 
	sap.nIdSimAudModPasaporte,
	sap.sProcedimiento,
	--[sDataEntrada] = CONVERT(VARCHAR(8000), sap.xDataEntrada),
	--[sDataSalida] = CONVERT(VARCHAR(8000), sap.xDataSalida),
	sap.dFecha
	INTO SimAudModPasaporte2
FROM SimAudModPasaporte sap
WHERE 
	sap.sProcedimiento = 'usp_RegistroPasaporteSIM_PE' 

-- Index ...
CREATE NONCLUSTERED INDEX IX_SimAudModPasaporte2_sProcedimiento
    ON dbo.SimAudModPasaporte2(sProcedimiento)

CREATE NONCLUSTERED INDEX IX_SimAudModPasaporte2_sDataEntrada
    ON dbo.SimAudModPasaporte2(sDataEntrada)

SELECT 
	pase.* ,
	[sMotivoNoMigrado] = (

								SELECT 
									TOP 1 
									-- [dbo].ufn_ExtraeMensajeDeSimAudModPasaporte(sap.xDataSalida)
									sap.xDataSalida
								FROM [dbo].[SimAudModPasaporte] sap
								WHERE 
									sap.sProcedimiento = 'usp_RegistroPasaporteSIM_PE' 
									AND sap.sDataEntrada LIKE '%<sNumeroPasaporte>' + pase.sNumeroPasaporte + '</sNumeroPasaporte>%'
								ORDER BY
									sap.dFecha DESC

							)
FROM #tmp_pase_nomigrados_simpas pase

-- Test ...
SELECT COUNT(1) FROM #tmp_pase_nomigrados_simpas pase
SELECT * FROM #tmp_pase_nomigrados_simpas pase
--================================================================================================================================*/


/*░
	→ 4. Pasaportes electrónicos vencidos con estado `E | Emitido` en SimPasaporte ...
================================================================================================================================*/

-- 4.1
DROP TABLE IF EXISTS #tmp_pase_migradosvencidos_estado_E
SELECT 
	spas.*
INTO #tmp_pase_migradosvencidos_estado_E
FROM BD_SIRIM.dbo.RimPasaporte pase
JOIN SimTramite st ON pase.sNumeroTramite = st.sNumeroTramite
JOIN SimPasaporte spas ON st.sNumeroTramite = spas.sNumeroTramite
WHERE
	spas.sEstadoActual = 'E' -- Emitido
	AND DATEDIFF(DD, GETDATE(), pase.dFechaCaducidad) <= 0

-- 4.2 Final: ...
SELECT 
	spas.sNombre,
	spas.sPaterno,
	spas.sMaterno,
	spas.sSexo,
	spas.dFechaNacimiento,
	spas.sNumeroTramite,
	spas.sPasNumero,
	spas.sEstadoActual,
	spas.dFechaEmision,
	spas.dFechaExpiracion
	INTO tmp_pase_migradosvencidos_estado_E
FROM #tmp_pase_migradosvencidos_estado_E spas

--================================================================================================================================*/

/*░
	→ 5. Pasaportes mecanizados vencidos con estado `E | Emitido` en SimPasaporte ...
================================================================================================================================*/

-- Base: 3,954,465
-- 5.1	EXPEDICION DE PASAPORTE
DROP TABLE IF EXISTS #tmp_pasm_migradosvencidos_estado_E
SELECT 
	spas.*
	INTO #tmp_pasm_migradosvencidos_estado_E 
FROM SimPasaporte spas 
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
WHERE
	st.bCancelado = 0
	AND st.bCulminado = 1
	AND st.nIdTipoTramite = 2 -- 2 | EXPEDICION DE PASAPORTE
	AND spas.sEstadoActual = 'E' -- Emitido
	AND DATEDIFF(DD, GETDATE(), spas.dFechaExpiracion) <= 0

-- 5.2 Final: ...
DROP TABLE IF EXISTS tmp_pasm_migradosvencidos_estado_E
SELECT 
	spas.sNombre,
	spas.sPaterno,
	spas.sMaterno,
	spas.sSexo,
	spas.dFechaNacimiento,
	spas.sNumeroTramite,
	spas.sPasNumero,
	spas.sEstadoActual,
	spas.dFechaEmision,
	spas.dFechaExpiracion
	INTO tmp_pasm_migradosvencidos_estado_E
FROM #tmp_pasm_migradosvencidos_estado_E spas
ORDER BY spas.sNumeroTramite
OFFSET 1000002 ROWS
FETCH NEXT 500000 ROWS ONLY

--================================================================================================================================*/
