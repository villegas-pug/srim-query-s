USE SIM
GO

-- MACEDONIA  → MAC	EX R.YUG.MACEDONIA
-- KAZAJISTÁN → KAZ | KAZAJSTAN
DECLARE @destino CHAR(3) = 'KAZ'
;WITH cte_mm_last AS (

	SELECT 
		mm.sTipo,
		mm.sIdMovMigratorio,
		mm.nAñoControl
	FROM (
	
		SELECT 
			[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
			smm.sTipo,
			smm.sIdMovMigratorio,
			smm.sIdPaisMov,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		WHERE
			smm.bAnulado = 0
			AND smm.dFechaControl BETWEEN '2016-01-01 00:00:00.000' AND '2023-02-19 23:59:59.999'
			AND smm.sTipo IN ('E', 'S')
			AND smm.sIdPaisNacionalidad = 'PER'
			AND smm.sIdPaisMov = @destino

	) mm
	/*WHERE 
		nFila_mm = 1
		--AND mm.sTipo = 'S'
		AND mm.sIdPaisMov = @destino*/

) SELECT * FROM cte_mm_last mm
PIVOT (
	COUNT(mm.sIdMovMigratorio) FOR mm.nAñoControl IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv_mac
