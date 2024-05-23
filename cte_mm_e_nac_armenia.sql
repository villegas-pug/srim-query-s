USE SIM
GO

;WITH cte_mm_e_nac_armenia AS (
	SELECT 
		DATEPART(YYYY, smm.dFechaControl) nAño,
		smm.sTipo [sTipoMovMig],
		smm.sIdMovMigratorio
	FROM dbo.SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
		AND smm.sIdPaisNacimiento = 'ARM'
		AND smm.sTipo = 'E'
		AND smm.nIdCalidad IN (40, 41, 227) -- Calidad `Turista`
) SELECT * FROM cte_mm_e_nac_armenia mm
PIVOT(
	COUNT(mm.sIdMovMigratorio) FOR mm.nAño IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022])
) pv


/*? Test ... */
-- SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%arm%'
-- SELECT * FROM dbo.SimCalidadMigratoria scm WHERE scm.sDescripcion LIKE '%tur%'
