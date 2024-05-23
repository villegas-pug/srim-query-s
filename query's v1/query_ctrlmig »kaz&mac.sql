USE SIM
GO

-- KAZAJISTÁN → KAZ | KAZAJSTAN
;WITH cte_mm_kaz AS (

	SELECT 
		[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
		smm.sTipo,
		[sNacionalidad] = sp.sNacionalidad,
		smm.sIdMovMigratorio
	FROM SimMovMigra smm
	JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2023-02-15 23:59:59.999'
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad IN ('KAZ')

) SELECT * FROM cte_mm_kaz mm
PIVOT (
	COUNT(mm.sIdMovMigratorio) FOR mm.nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv_kaz

-- MACEDONIA  → MAC	EX R.YUG.MACEDONIA
;WITH cte_mm_mac AS (

	SELECT 
		[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
		smm.sTipo,
		[sNacionalidad] = sp.sNacionalidad,
		smm.sIdMovMigratorio
	FROM SimMovMigra smm
	JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2023-02-15 23:59:59.999'
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad IN ('MAC')

) SELECT * FROM cte_mm_mac mm
PIVOT (
	COUNT(mm.sIdMovMigratorio) FOR mm.nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv_mac

-- KAZAJISTÁN → KAZ | KAZAJSTAN