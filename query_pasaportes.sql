USE SIM
GO

-- =================================================================================================================================================================================
-- Ver 1.1: PAS-E Emitidos ...
-- =================================================================================================================================================================================
DROP TABLE IF EXISTS SimPasaporteRim
DECLARE @fecIni DATETIME = '2016-01-01 00:00:00.000',
		@fecFin DATETIME = CONCAT(CONVERT(DATE, DATEADD(DD, -1, GETDATE())), ' 23:59:59.999')

SELECT
	stp.sPasNumero,
	st.uIdPersona,
	[sNumeroDocumento] = CONCAT('''', stp.sNumeroDoc),
	
	[dFechaTramite] = (
						SELECT TOP 1 spas.dFechaEmision
						FROM dbo.SimPasaporte spas
						WHERE spas.sPasNumero = stp.sPasNumero 
						ORDER BY spas.dFechaEmision DESC
	),

	[dFechaEntrega] = stp.dFechaHoraAud,

	[dFechaExpiracion] = (SELECT spas.dFechaExpiracion FROM dbo.SimPasaporte spas 
						  WHERE spas.sPasNumero = stp.sPasNumero),
	[dFechaAnulacion] = (SELECT spas.dFechaAnulacion FROM dbo.SimPasaporte spas 
						 JOIN SimTramite s_st ON s_st.sNumeroTramite = spas.sNumeroTramite
						 WHERE 
							spas.sPasNumero = stp.sPasNumero 
							AND s_st.nIdTipoTramite = 4), -- 4 | ANULACION DE PASAPORTE 

	[sEstadoActual] = CASE (SELECT TOP 1 spas.sEstadoActual 
									FROM dbo.SimPasaporte spas 
								    WHERE spas.sPasNumero = stp.sPasNumero 
								    ORDER BY spas.dFechaHoraAud DESC)
								WHEN 'A' THEN 'ANULADO'
								WHEN 'C' THEN 'NO EXPEDIDO'
								WHEN 'E' THEN 'EXPEDIDO'
								WHEN 'N' THEN 'NUEVO'
								WHEN 'R' THEN 'REVALIDADO'
								WHEN 'X' THEN 'CANCELADO'
								WHEN 'S' THEN 'SUSPENDIDO'
						  END,

	[sEtapaActual] = se.sDescripcion,
	[¿Entregado?] = IIF(stp.nIdEtapaActual = 9, 'Si', 'No'),

	su.sNombre [sUbigeoDomicilio],
	stp.sSexo,
	sp.dFechaNacimiento,
	sd.sNombre [sDependencia],
	[¿Uso el pas-e?] = IIF(EXISTS(SELECT 1 FROM SimMovMigra smm 
								  WHERE 
										smm.uIdPersona = sp.uIdPersona 
										AND smm.sNumeroDoc = stp.sPasNumero)
						   , 'Si', 'No')
	INTO SimPasaporteRim
FROM SimTramite st
JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
LEFT OUTER JOIN SimEtapa se ON stp.nIdEtapaActual = se.nIdEtapa
LEFT OUTER JOIN SimUbigeo su ON stp.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT OUTER JOIN SimPais spais ON stp.sIdPaisNacimiento = spais.sIdPais
LEFT OUTER JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
WHERE
	st.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
	AND stp.sEstadoAnterior IN ('N', 'E')
	AND stp.dFechaHoraAud BETWEEN @fecIni AND @fecFin -- Fecha de emisión en SimTramitePas
	AND stp.nIdEtapaActual IN (5, 6, 7, 9) -- Etapa de PAS: IMPRESION | CONTROL DE CALIDAD | ENTREGA DE PASAPORTE
	-- PAS-E Sintaxis
	AND LEN(LTRIM(RTRIM(stp.sPasNumero))) = 9
	AND stp.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (stp.sPasNumero LIKE '11%' OR stp.sPasNumero LIKE '12%')
	/*AND
		(SELECT TOP 1 spas.sEstadoActual 
		FROM dbo.SimPasaporte spas 
		WHERE spas.sPasNumero = stp.sPasNumero 
		ORDER BY spas.dFechaHoraAud DESC) = 'S'*/


/*► Test ... */
SELECT TOP 1000 * FROM SimPasaporteRim spr WHERE spr.sEstadoActual IS NULL
SELECT TOP 1 * FROM SimPasaporteRim

SELECT 
	-- COUNT(1)
	st.sNumeroTramite,
	-- sp.dFechaEmision,
	st.dFechaHora,
	stp.dFechaHoraAud
FROM SimTramitePas stp 
-- JOIN SimPasaporte sp ON stp.sNumeroTramite = sp.sNumeroTramite
JOIN SimTramite st ON stp.sNumeroTramite = st.sNumeroTramite
WHERE 
	st.nIdTipoTramite = 90
	-- AND st.dFechaHoraAud BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	-- AND st.dFechaHoraReg BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	-- AND sp.dFechaEmision BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	AND stp.sNumeroTramite = 'LM220396500'

SELECT * FROM SimPasaporte sp 
WHERE 
	sp.sNumeroTramite = 'AI220134377'
	-- sp.sPasNumero = 'AI220134457'

SELECT * FROM SimTramitePas stp 
WHERE 
	stp.sNumeroTramite = 'AI220134377'
	-- stp.sPasNumero = '122269933'

SELECT * FROM SimTramite st WHERE st.sNumeroTramite = 'AI220134457'


-- Test: PAS-E
;WITH cte_pas AS (
	SELECT 
		-- DATEPART(DD, spr.dFechaEmision) nDia,
		DATEPART(DAY, spr.dFechaAprobEtapa) nDia,
		spr.uIdPersona
	FROM SimPasaporteRim spr
	WHERE 
		-- spr.dFechaEmision  >= '2022-07-01 00:00:00.000' -- AND '2022-07-31 23:59:59.999'
		spr.dFechaAprobEtapa  >= '2022-07-01 00:00:00.000' -- AND '2022-07-31 23:59:59.999'
		AND spr.sEtapaActual != 'ENTREGA DE PASAPORTE'
) SELECT * FROM cte_pas cte
PIVOT(
	-- COUNT(cte.uIdPersona) FOR cte.nMes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
	COUNT(cte.uIdPersona) FOR cte.nDia IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], 
										   [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30], [31])
) pv


/*► */
;WITH cte_pas AS (
	SELECT 
		DATEPART(YYYY, spr.dFechaEmision) nAñoEmision,
		spr.[¿Uso el pas-e?],
		spr.uIdPersona
	FROM SimPasaporteRim spr
) SELECT * FROM cte_pas pas
PIVOT(
	COUNT(pas.uIdPersona) FOR pas.nAñoEmision IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022])
) pv

SELECT TOP 10 * FROM SimTramitePas stp WHERE stp.nIdEtapaActual = 7
ORDER BY stp.dFechaHoraAud DESC

-- Etapas de PAS-E
SELECT se.sDescripcion, sett.* FROM SimEtapaTipoTramite sett
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
	sett.nIdTipoTramite = 90
ORDER BY sett.nSecuencia

-- Entregados hoy ...
SELECT 
	COUNT(1) 
-- FROM SimTramitePas stp
FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
JOIN SimTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
WHERE 
	-- stp.dFechaHoraAud BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	-- st.dFechaHoraReg BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	spas.dFechaEmision BETWEEN '2022-07-20 00:00:00.000' AND '2022-07-20 23:59:59.999'
	AND st.nIdTipoTramite = 90 -- PAS-E
	AND stp.sEstadoAnterior IN ('N', 'E')
	AND stp.nIdEtapaActual IN (7, 9)
	-- Caracteristicas PAS-E
	/*AND LEN(LTRIM(RTRIM(stp.sPasNumero))) = 9
	AND stp.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (stp.sPasNumero LIKE '11%' OR stp.sPasNumero LIKE '12%')*/

/*
DROP INDEX ix_SimPasaporteRim_sNumeroDoc
	ON SimPasaporteRim(sNumeroDoc)
*/
SELECT TOP 10 * FROM SimTramitePas
SELECT TOP 10000 * FROM SimPasaporteRim WHERE uIdPersona = '66EB5282-29DE-4DE7-A098-02F705040D0D'
SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%arm%'

SELECT TOP 1 * FROM SimTramitePasPrv
SELECT TOP 1 * FROM SimObsEtapaTraPas
SELECT TOP 1 * FROM SimImpresionPas
SELECT TOP 1 * FROM SimAuditoriaAsoDes




CREATE NONCLUSTERED INDEX ix_SimPasaporteRim_sNumeroDoc
    ON SimPasaporteRim(sNumeroDoc)

CREATE NONCLUSTERED INDEX ix_SimPasaporteRim_uIdPersona
    ON SimPasaporteRim(uIdPersona)
	 
-- Test ...
-- ...
SELECT 
	spr.uIdPersona,
	spr.dFechaEmision
FROM SimPasaporteRim spr
WHERE spr.uIdpersona = '0CC0D693-D090-41C6-BAFD-CAE3765A9003'


SELECT spr.uIdPersona, spr.sNumeroDoc, COUNT(1) FROM SimPasaporteRim spr
GROUP BY spr.uIdPersona, spr.sNumeroDoc
HAVING COUNT(1) >= 15

SELECT COUNT(1) FROM SimPasaporteRim spr WHERE spr.dFechaEmision IS NULL
-- =====================================================================================================================================================================



-- =====================================================================================================================================================================
-- ◄► Extraer PAS-E, que registraron DOC distintos ...
-- =====================================================================================================================================================================

-- STEP-01: Extraer e insertar en `tmp`, registros con DOC'S distintos ...
DROP TABLE IF EXISTS #pas_dni_distinct
SELECT 
	spr.uIdPersona, 
	COUNT(DISTINCT spr.sNumeroDoc) [nContarDni_Distinct]
	INTO #pas_dni_distinct
FROM dbo.SimPasaporteRim spr
GROUP BY spr.uIdPersona
HAVING COUNT(DISTINCT spr.sNumeroDoc) > 1

CREATE NONCLUSTERED INDEX ix_pas_dni_distinct_uIdPersona
    ON #pas_dni_distinct(uIdPersona)

-- STEP-02: Final
-- SELECT * FROM #pas_dni_distinct
SELECT
	(sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno) [sCiudadano],
	sp.dFechaNacimiento,
	spr.* 
FROM dbo.SimPasaporteRim spr
JOIN SimPersona sp ON sp.uIdPersona = spr.uIdPersona
WHERE
	spr.uIdPersona IN (SELECT pdd.uIdPersona FROM #pas_dni_distinct pdd)
ORDER BY
	spr.uIdPersona
-- =====================================================================================================================================================================




-- =====================================================================================================================================================================
-- ::. Extracción de PAS-E entre 13 y 17 años ::.
-- =====================================================================================================================================================================

-- STEP-01: Extraer PAS-E
-- =================================================================================
DROP TABLE IF EXISTS #pas_emitidos
-- SELECT TOP 1000 * FROM #pas_emitidos
SELECT 
	stp.sIdDocumento,
	stp.sNumeroDoc,
	stp.sPasNumero,
	CONVERT(DATE, stp.dFechaHoraAud) [dFechaEmision],
	[sEstado] = CASE stp.sEstadoAnterior
							WHEN 'A' THEN 'ANULADO'
							WHEN 'C' THEN 'NO EXPEDIDO'
							WHEN 'E' THEN 'EXPEDIDO'
							WHEN 'N' THEN 'NUEVO'
							WHEN 'R' THEN 'REVALIDADO'
							WHEN 'X' THEN 'CANCELADO'
					  END,
	se.sDescripcion [sEtapa],
	spais.sNombre [sPaisNacimiento],
	su.sNombre [sUbigeoNacimiento],
	stp.sSexo,
	stp.dFechaNacimiento,
	sd.sNombre [sDependencia]
	INTO #pas_emitidos
FROM SimTramite st
LEFT OUTER JOIN SimTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
LEFT OUTER JOIN SimEtapa se ON stp.nIdEtapaActual = se.nIdEtapa
LEFT OUTER JOIN SimUbigeo su ON stp.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT OUTER JOIN SimPais spais ON stp.sIdPaisNacimiento = spais.sIdPais
LEFT OUTER JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
WHERE
	stp.sEstadoAnterior IN ('N', 'E')
	AND stp.dFechaHoraAud >= '2016-01-01 00:00:00.000' -- Fecha de emisión en SimTramitePas
	AND st.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
	AND stp.nIdEtapaActual = 9 -- Etapa de PAS: ENTREGA DE PASAPORTE
	-- PAS-E Sintaxis
	AND LEN(LTRIM(RTRIM(stp.sPasNumero))) = 9
	AND stp.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (stp.sPasNumero LIKE '11%' OR stp.sPasNumero LIKE '12%')

/*► Create-Index: #pas_emitidos ... */
CREATE NONCLUSTERED INDEX ix_pas_emitidos_sPasNumero
    ON #pas_emitidos(sPasNumero)

-- STEP-02: Extraer → dFechaExpiracion PAS-E
-- =================================================================================
SELECT 
	pe.*,
	sp.dFechaExpiracion
	INTO #pas_emitido_expiracion
FROM #pas_emitidos pe
LEFT OUTER JOIN dbo.SimPasaporte sp ON pe.sPasNumero = sp.sPasNumero


/*► Create index: #pas_emitido_expiracion */
CREATE UNIQUE NONCLUSTERED INDEX ix_#pas_emitido_expiracion_sPasNumero
    ON #pas_emitido_expiracion(sPasNumero)


-- STEP-03: Extraer PAS-E en el rango de 13 - 17
-- =================================================================================
SELECT * FROM #pas_e_expira_13y17ed
SELECT 
	pee.*
	INTO #pas_e_expira_13y17ed
FROM #pas_emitido_expiracion pee
WHERE
	DATEDIFF(YYYY, pee.dFechaNacimiento, pee.dFechaEmision) BETWEEN 13 AND 17

/*► Create index: #pas_e_expira_13y17ed ... */
DROP INDEX ix_#pas_e_expira_13y17ed_sPasNumero ON #pas_e_expira_13y17ed
CREATE UNIQUE NONCLUSTERED INDEX ix_#pas_e_expira_13y17ed_sPasNumero
    ON #pas_e_expira_13y17ed(sPasNumero, dFechaNacimiento)

-- STEP-04-FINAL: Extraer PAS-E, que realizaron MovMigra `S` ...
-- =================================================================================
SELECT 
	smm.uIdPersona,
	pas.*,
	smm.dFechaControl,
	smm.sTipo,
	scm.sDescripcion [sCalidad_Movimiento_Migra],
	smm.sIdPaisNacionalidad,
	smm.sIdDocumento [sIdDocumento_MovMigra],
	smm.sNumeroDoc [sNumDoc_MovMigra],
	sd.sNombre [sDependencia_MovMigra],
	smm.sIdPaisMov,
	svt.sDescripcion [sViaTransporte],
	smm.sIdPaisResidencia [sIdPaisResidencia_MovMigra],
	sprof.sDescripcion [sProfesion_Mov_Migra],
	smm.sIdPaisNacimiento [sIdPaisNacimiento_MovMigra],
	smm.sObservaciones [sObs_Mov_Migra]
	INTO #pas_final
FROM #pas_e_expira_13y17ed pas
JOIN dbo.SimMovMigra smm ON pas.sPasNumero = smm.sNumeroDoc
JOIN dbo.SimPersona sp ON smm.uIdPersona = sp.uIdPersona
JOIN dbo.SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
JOIN dbo.SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
JOIN dbo.SimViaTransporte svt ON smm.sIdViaTransporte = svt.sIdViaTransporte
JOIN dbo.SimProfesion sprof ON smm.sIdProfesion = sprof.sIdProfesion
WHERE
	smm.bAnulado = 0
	AND smm.sTipo = 'S'
	AND (pas.sPasNumero = smm.sNumeroDoc AND pas.dFechaNacimiento = sp.dFechaNacimiento)
ORDER BY smm.uIdPersona


CREATE NONCLUSTERED INDEX ix_pas_final_uIdPersona
    ON #pas_final(uIdPersona)

/*► Resumen: Movimientos migratorios por persona */
SELECT COUNT(1) FROM #pas_final
SELECT TOP 1000 * FROM #pas_final pf ORDER BY pf.uIdPersona
SELECT 
	t_mm_pas.nTotal_MovMigra,
	[nTotal_Persona] = COUNT(1)
FROM (
	SELECT 
		pf.sPasNumero,
		COUNT(1) [nTotal_MovMigra]
	FROM #pas_final pf
	JOIN SimPersona sp ON pf.uIdPersona = sp.uIdPersona
	GROUP BY pf.sPasNumero
) t_mm_pas
GROUP BY t_mm_pas.nTotal_MovMigra
ORDER BY t_mm_pas.nTotal_MovMigra DESC




-- Clean-up ...
DROP TABLE IF EXISTS #pas_emitidos
DROP TABLE IF EXISTS #pas_emitido_expiracion
DROP TABLE IF EXISTS #pas_e_expira_13y17ed

-- Test ...
SELECT 
	smm.sNombres [sCiudadano_MM],
	smm.sNumeroDoc [sNumDoc_MM],
	sp.dFechaNacimiento [dFechaNac_MM],
	stp.sNombre [sCiudadano_Pas],
	stp.sNumeroDoc [sNumDoc_Pas],
	stp.dFechaNacimiento [dFechaNac_Pas]
FROM dbo.SimMovMigra smm
JOIN dbo.SimPersona sp ON smm.uIdPersona = sp.uIdPersona
JOIN dbo.SimTramitePas stp ON smm.sNumeroDoc = stp.sPasNumero 
WHERE 
	stp.sPasNumero = '117213919'

-- =====================================================================================================================================================================



-- ============================================================================================================================================================================================================
-- Test: ...
-- ============================================================================================================================================================================================================
-- X | Sin Estado
-- R | Revalidado
-- N | Nuevo
-- E | Expedido
-- C | No Expedido
-- A | Anulado
-- PU190003585 KS170000716 LM170162751
-- E428D250-D41D-4D70-9803-865524C0FBB3
SELECT 
	-- st.uIdPersona,
	(sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno) [sCiudadano],
	st.sNumeroTramite,
	st.nIdTipoTramite,
	st.dFechaHoraReg [dFechaTramite],
	[dFechaHoraAud_Tramite] = st.dFechaHoraAud,
	stt.sDescripcion [sTipoTramite],
	DATEPART(YYYY, st.dFechaHoraReg) nAñoTram,
	DATEPART(MM, st.dFechaHoraReg) nMesTram, 
	sd.sNombre [sDependencia],
	spas.sNumeroTramite [sNumeroTramite_Pas],
	spas.sPasNumero,
	spas.sEstadoActual,
	spas.dFechaEmision,
	spas.dFechaExpiracion,
	spas.dFechaAnulacion,
	spas.dFechaHoraAud,
	spas.sObservaciones [sObsPasaporte],
	st.sObservaciones [sObsTramite],
	-- spas.* ,
	stp.*
FROM SimPasaporte spas
RIGHT OUTER JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
LEFT OUTER JOIN SimTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
LEFT OUTER JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
LEFT OUTER JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
LEFT OUTER JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
WHERE
	st.sNumeroTramite IN ('PU190003585', 'KS170000716', 'LM170162751')
	-- sp.uIdPersona = 'E428D250-D41D-4D70-9803-865524C0FBB3' -- ROSA ALCIRA, ACUÑA PINTADO
	AND stt.nIdTipoTramite NOT IN (17)
	-- AND sp.uIdPersona = '0CC0D693-D090-41C6-BAFD-CAE3765A9003' --CAMPOS	NUÑEZ, HUGO ARMANDO
ORDER BY
	st.dFechaHoraReg DESC -- Fecha inicio trámite

-- Etapas trámite: `Expedición de Pasaporte`
SELECT se.sDescripcion [sEtapa], sett.* 
FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE sett.nIdTipoTramite = 90 -- Expedición paraporte
ORDER BY sett.nSecuencia

-- Contar trámites `Nuevos` y `Expedidos` en SimTramitePas
SELECT 
	sd.sNombre [sDependencia],
	COUNT(1) 
FROM SimTramitePas stp
JOIN SimTramite st ON stp.sNumeroTramite = st.sNumeroTramite
JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
WHERE 
	stp.sEstadoAnterior IN ('N', 'E')
	AND stp.dFechaHoraAud >= '2016-01-01 00:00:00.000'
	AND st.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
	AND stp.nIdEtapaActual = 9 -- Etapa de PAS: ENTREGA DE PASAPORTE
	-- PAS-E Sintaxis
	AND LEN(LTRIM(RTRIM(stp.sPasNumero))) = 9
	AND stp.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (stp.sPasNumero LIKE '11%' OR stp.sPasNumero LIKE '12%')
GROUP BY sd.sNombre
ORDER BY COUNT(1) DESC

-- Contar PAS en estado `C` → No Expedido ...  
SELECT 
	DATEPART(YYYY, spas.dFechaEmision) nAñoEmision,
	COUNT(1)
FROM SimPasaporte spas
WHERE
	spas.sEstadoActual = 'C'
GROUP BY DATEPART(YYYY, spas.dFechaEmision)
ORDER BY DATEPART(YYYY, spas.dFechaEmision) DESC

-- Contar otros tipos de trámites en SimTramitePas
SELECT 
	stt.nIdTipoTramite,
	stt.sDescripcion [sTipoTramite],
	COUNT(1)
FROM SimTramite st
JOIN SImTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
GROUP BY stt.nIdTipoTramite, stt.sDescripcion
ORDER BY COUNT(1) DESC

-- Contar otros estados en SimTramitePas
SELECT 
	stp.sEstadoAnterior,
	COUNT(1)
FROM SImTramitePas stp 
WHERE 
	stp.dFechaHoraAud >= '2016-01-01 00:00:00.000'
	AND stp.nIdEtapaActual = 9
GROUP BY stp.sEstadoAnterior
ORDER BY COUNT(1) DESC
-- =================================================================================================================================================================================

-- =================================================================================================================================================================================
-- ◄► PAS-E No migrados a SimPasaporte ...
-- =================================================================================================================================================================================
SELECT 
	st.uIdPersona,
	stp.sIdDocumento,
	CONCAT('''', stp.sNumeroDoc) [sNumeroDoc],
	CONCAT('''', stp.sPasNumero) [sNumeroDoc],
	stp.dFechaHoraAud [dFechaEmision],
	[dFechaExpiracion] = (SELECT spas.dFechaExpiracion FROM dbo.SimPasaporte spas 
						 WHERE spas.sPasNumero = stp.sPasNumero),
	[dFechaAnulacion] = (SELECT spas.dFechaAnulacion FROM dbo.SimPasaporte spas 
						 JOIN SimTramite s_st ON s_st.sNumeroTramite = spas.sNumeroTramite
						 WHERE 
							spas.sPasNumero = stp.sPasNumero 
							AND s_st.nIdTipoTramite = 4), -- 4 | ANULACION DE PASAPORTE 
	[sEstadoActual] = CASE (SELECT TOP 1 spas.sEstadoActual 
									FROM dbo.SimPasaporte spas 
								    WHERE spas.sPasNumero = stp.sPasNumero 
								    ORDER BY spas.dFechaHoraAud DESC)
								WHEN 'A' THEN 'ANULADO'
								WHEN 'C' THEN 'NO EXPEDIDO'
								WHEN 'E' THEN 'EXPEDIDO'
								WHEN 'N' THEN 'NUEVO'
								WHEN 'R' THEN 'REVALIDADO'
								WHEN 'X' THEN 'CANCELADO'
						  END,
	[sEstadoAnterior] = CASE stp.sEstadoAnterior
								WHEN 'A' THEN 'ANULADO'
								WHEN 'C' THEN 'NO EXPEDIDO'
								WHEN 'E' THEN 'EXPEDIDO'
								WHEN 'N' THEN 'NUEVO'
								WHEN 'R' THEN 'REVALIDADO'
								WHEN 'X' THEN 'CANCELADO'
						  END,
	se.sDescripcion [sEtapa],
	stp.sNombre,
	stp.sMaterno,
	stp.sPaterno,
	sprof.sDescripcion [sProfesion],
	stp.sSexo,
	stp.dFechaNacimiento,
	spais.sNombre [sPaisNacimiento],
	su.sNombre [sUbigeoDomicilio],
	sd.sNombre [sDependencia]
FROM SimTramite st
JOIN SimTramitePas stp ON st.sNumeroTramite = stp.sNumeroTramite
LEFT OUTER JOIN SimEtapa se ON stp.nIdEtapaActual = se.nIdEtapa
LEFT OUTER JOIN SimUbigeo su ON stp.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT OUTER JOIN SimPais spais ON stp.sIdPaisNacimiento = spais.sIdPais
LEFT OUTER JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
LEFT OUTER JOIN SimProfesion sprof ON stp.sIdProfesion = sprof.sIdProfesion
WHERE
	stp.sEstadoAnterior IN ('N', 'E')
	AND stp.dFechaHoraAud >= '2016-01-01 00:00:00.000' -- Fecha de emisión en SimTramitePas
	AND st.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
	AND stp.nIdEtapaActual = 9 -- Etapa de PAS: ENTREGA DE PASAPORTE
	-- Caracteristicas de PAS-E
	AND LEN(LTRIM(RTRIM(stp.sPasNumero))) = 9
	AND stp.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (stp.sPasNumero LIKE '11%' OR stp.sPasNumero LIKE '12%')
	-- Regla ◄► PAS-E No migrados a SimPasaporte ...
	AND NOT EXISTS (SELECT 1 FROM SimPasaporte spas WHERE spas.sNumeroTramite = st.sNumeroTramite)

-- Test ...
SELECT * FROM SimPasaporte spas WHERE spas.sNumeroTramite = 'CL190069256'
SELECT * FROM SimPasaporte spas WHERE spas.sPasNumero = '116000426' 

/*
116000226
116000426
116000567
116000586
116000786
116000791
116001201
116001436
116001474
*/

-- =====================================================================================================================================================================