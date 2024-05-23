USE SIM
GO

/*�
-- VEN, COL, BOL, MEX
==============================================================================================================================================================*/
-- Backup: xTotalExtranjerosPeru
SELECT * INTO BD_SIRIM.dbo.RimTotalExtranjerosPeru FROM xTotalExtranjerosPeru


-- STEP-01: ...
DROP TABLE IF EXISTS #tmp_minjus
SELECT
	[dFechaIngreso] = r.Ingreso,
	[sSexo] = r.Sexo,
	[dFechaNacimiento] = r.FechaNacimiento,
	[nEdad] = r.Edad,
	[sRangoEdad] = r.RangoEdad,
	[sCalidadTipo] = r.CalidadTipo, 
	[sCalidadMigratoria] = r.CalidadMigratoria,
	[sSituacionMigratoria] = CASE 
										WHEN CalidadMigratoria = 'Permanente' or CalidadMigratoria = 'Inmigrante' THEN 'Permanente'
										WHEN CalidadTipo = 'R' and (CalidadMigratoria != 'Permanente' and CalidadMigratoria != 'Inmigrante') THEN 'Residente'
										WHEN CalidadMigratoria = 'Turista' THEN 'Turista'
										ELSE 'Otras calidades temporales'
									END,
	[sNacionalidad] = r.Nacionalidad
INTO #tmp_minjus
FROM xTotalExtranjerosPeru r
WHERE
	r.Ingreso BETWEEN '2016-01-01 00:00:00.000' AND '2022-12-31 23:59:59.999'
	AND r.Nacionalidad IN (
			'BOLIVIANA',
			'COLOMBIANA',
			'MEXICANA',
			'VENEZOLANA'
		)

-- STEP-02: Total poblaci�n ...
SELECT * 
FROM (
	SELECT [bActivo] = 1, sNacionalidad FROM #tmp_minjus
) tmp
PIVOT (
	COUNT(bActivo) FOR [sNacionalidad] IN ([VENEZOLANA], [COLOMBIANA], [MEXICANA], [BOLIVIANA])
) pv

-- ...
SELECT 
	/*TOP 10 
	[sTipoTramite] = stt.sDescripcion,
	svpda.**/
	[nTotal] = COUNT(1)
FROM [dbo].[SimVerificaPDA] svpda
JOIN SimTipoTramite stt ON svpda.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	svpda.bActivo = 1
	AND svpda.nIdTipoTramite = 109
	AND svpda.dFechaHoraAud <= '2022-12-31 23:59:59.999'


-- ...
SELECT EOMONTH(GETDATE(), -1)











/*==============================================================================================================================================================*/







