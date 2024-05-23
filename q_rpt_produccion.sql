USE SIRIM
GO

-- Método-01 ...
SELECT (

	(SELECT 
		COUNT(1) 
	FROM RimTablaDinamica t
	JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
	JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
	JOIN SidUsuario u ON a.uIdUsrAnalista = u.uIdUsuario
	JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
	WHERE
		CONVERT(DATE, p.dFechaFin) BETWEEN '2022-10-01' AND '2022-10-25'
		AND u.sGrupo = 'ANALISIS')

		+

	(SELECT 
		COUNT(1) 
	FROM RimTablaDinamica t
	JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
	JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
	JOIN SidUsuario u ON a.uIdUsrAnalista = u.uIdUsuario
	JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
	WHERE
		CONVERT(DATE, p.dFechaFin) BETWEEN '2022-10-01' AND '2022-10-21'
		AND u.uIdUsuario = '98C257E9-FE90-4F56-BB0A-5E78B5E00CAE')

)

-- Método-02 ...
SELECT * FROM RimTablaDinamica



SELECT 
	ua.sNombres,
	uc.sGrupo,
	[nTotalAnalizados] = COUNT(1) 
FROM RimTablaDinamica t
JOIN SidUsuario uc ON t.uIdUsrCreador = uc.uIdUsuario
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN SidUsuario ua ON a.uIdUsrAnalista = ua.uIdUsuario
JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
WHERE
	CONVERT(DATE, p.dFechaFin) BETWEEN '2022-09-29' AND '2022-10-25'
	AND uc.sLogin != 'rguevarav'
	-- AND uc.sGrupo = 'ANALISIS'
	-- AND t.sNombre = 'ENTRADA_INDIA_ENERO_OCTUBRE_2022'
GROUP BY
	ua.sNombres,
	uc.sGrupo
ORDER BY
	uc.sGrupo


	usrAnalista
totalAnalizados

CREATE OR ALTER PROCEDURE dbo.usp_Rim_Rpt_Produccion_Diaria
(
	@fecIni DATE,
	@fecFin DATE
)
AS
BEGIN

	SELECT 
		[usrAnalista] = ua.sNombres,
		[grupo] = uc.sGrupo,
		[totalAnalizados] = COUNT(1)
	FROM RimTablaDinamica t
	JOIN SidUsuario uc ON t.uIdUsrCreador = uc.uIdUsuario
	JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
	JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
	JOIN SidUsuario ua ON a.uIdUsrAnalista = ua.uIdUsuario
	JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
	WHERE
		CONVERT(DATE, p.dFechaFin) BETWEEN @fecIni AND @fecFin
		AND uc.sLogin != 'rguevarav'
		AND ua.sLogin NOT IN ('NPASTOR', 'EGOLIVERA')
	GROUP BY
		ua.sNombres,
		uc.sGrupo
	ORDER BY
		[totalAnalizados] DESC

END

SELECT * FROM SidUsuario



-- =====================================================================================================================
-- Reportes de producción 
-- =====================================================================================================================
-- 02Set2022
-- SELECT * FROM RimTablaDinamica
SELECT 
	[Fecha Asignacion] = CONVERT(DATE, a.dFechaAsignacion),
	[Fecha Analisis] = CONVERT(DATE, p.dFechaFin),
	[Analisista] = u.sNombres,
	[Base] = t.sNombre,
	tmp.*
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN SidUsuario u ON a.uIdUsrAnalista = u.uIdUsuario
JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
JOIN Dni_vinculado_3_4 tmp ON p.nIdRegistroAnalisis = tmp.nId
WHERE
	-- t.sNombre = 'ENTRADA_INDIA_ENERO_OCTUBRE_2022'
	t.sNombre = 'Dni_vinculado_3_4'
	-- t.sNombre = 'Pas_DNI_vinculado'
	AND CONVERT(DATE, p.dFechaFin) BETWEEN '2022-09-01' AND '2022-09-30'
ORDER BY tmp.nId

-- Test ...
-- EORMACHEA ►  $2a$10$HAK2h5ehnarFFmcHit4AOuVXfOac/jMkx8NcHYLWS9HcSjClthLB.
-- NPASTOR | $2a$10$QjdjjZ3Z1gB3mEuO1Wft3O43hX8xJTLarNC5Ah3RyO20YXejTFpi2
-- COMMON ► $2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO

UPDATE SidUsuario
	-- SET xPassword = '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO'
	SET xPassword = '$2a$10$QjdjjZ3Z1gB3mEuO1Wft3O43hX8xJTLarNC5Ah3RyO20YXejTFpi2'
WHERE sLogin = 'NPASTOR'

SELECT * FROM SidUsuario
UPDATE SidUsuario
	SET sGrupo = 'DEPURACION'
WHERE sLogin = 'RQUIROGA'

SELECT * FROM RimAsigGrupoCamposAnalisis a
ORDER BY a.dFechaAsignacion DESC

SELECT * FROM ENTRADA_JAPON_ENERO_OCTUBRE_2022

SELECT g.* FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
WHERE
	t.sNombre = 'ENTRADA_JAPON_ENERO_OCTUBRE_2022'

UPDATE RimGrupoCamposAnalisis
	SET sMetaFieldsCsv = 'nNUMERO_REGISTRO_a | int | 1_2_3_4_5, bVINCULACION_LOCATOR_a | VARCHAR(196) | SI_NO, nNUMERO_ACOMPANANTES_a | int | 1_2_3_4, bVIAJA_MENOR_a | VARCHAR(325) | SI_NO, sNOMBRE_MENOR_a | VARCHAR(MAX) | NOMBRE MENOR, sDOCUMENTO_MENOR_a | VARCHAR(MAX) | DOCUMENTO_MENOR, bUNICO_VIAJE_a | VARCHAR(434) | SI_NO, sRUTA_a | VARCHAR(MAX) | RUTA, bCALIDAD_MIGRATORIA_a | VARCHAR(482) | CALIDAD MIGRATORIA, dFECHA_VENCIMIENTO_RESIDENCIA_a | date | VENCIMIENTO RESIDENCIA, bULTIMO_MOV_a | VARCHAR(294) | E_S, dFCHA_ULT_MOV_a | date | FECHA_ULTI_MOV, bDNV_a | VARCHAR(403) | SI_NO, bSUNAT_a | VARCHAR(270) | SUNAT, nTRABAJADORES_EMPRESA_a | int | SUNAT, nCANTIDAD_TRABAJADORES_a | int | RIM, dFECHA_TERM_CONTR_a | date | RIM, dFECHA_INIC_CONTRATO_a | date | RIM, dFECHA_TERM_CONTRAT_a | date | RIM, sINFORMACION_INTERNET_a | VARCHAR(MAX) | INTERNET, sOBSERVACIONES_a | VARCHAR(MAX) | CASUISTICAS'
WHERE
	nIdGrupo = 32
-- =====================================================================================================================


-- =====================================================================================================================
-- Reportes de asignados ...
-- =====================================================================================================================

-- Dep's ...
DECLARE @ids_asigg_csv VARCHAR(MAX),
		@sql NVARCHAR(MAX)

-- STEP-01:
SET @ids_asigg_csv = (
	SELECT 
		STRING_AGG(CONCAT(' nId BETWEEN ', a.nRegAnalisisIni, ' AND ', a.nRegAnalisisFin), ' OR ')
	FROM RimTablaDinamica t
	JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
	JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
	WHERE
		t.sNombre = 'Dni_vinculado_3_4'
)

-- STEP-02:
SET @sql = N'SELECT * FROM Dni_vinculado_3_4 WHERE ' + @ids_asigg_csv
EXEC SP_EXECUTESQL @sql

-- STEP-03
SELECT 
	[Fecha Asignacion] = CONVERT(DATE, a.dFechaAsignacion),
	[Fecha Analisis] = CONVERT(DATE, p.dFechaFin),
	[Analisista] = u.sNombres,
	[Base] = t.sNombre,
	tmp.*
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN SidUsuario u ON a.uIdUsrAnalista = u.uIdUsuario
JOIN Dni_vinculado_3_4 tmp ON p.nIdRegistroAnalisis = tmp.nId
WHERE
	t.sNombre = 'Dni_vinculado_3_4'
ORDER BY tmp.nId

-- =====================================================================================================================