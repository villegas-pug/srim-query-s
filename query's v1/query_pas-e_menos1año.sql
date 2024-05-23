USE BD_SIRIM
GO

/*░
 -- Cantidad de personas que hayan sacado varios pasaportes en menos de un año ...
 -- rpt_varios_pas_menos1año
======================================================================================================================================================*/

/*
CREATE INDEX IX_TableName_Col1
    ON dbo.TableName
    (column_1)
*/

-- Dep's
DECLARE @cantPas INT = 2

;WITH cte_pase_1mas AS (

	SELECT * FROM BD_SIRIM.dbo.RimPasaporte rp3
	WHERE
		rp3.sNumeroDNI IN (
		
			SELECT DISTINCT rp2.sNumeroDNI FROM (

				SELECT 
					rp.*,
					[nFila] = ROW_NUMBER() OVER (PARTITION BY rp.sNumeroDNI ORDER BY rp.dFechaEntrega)
				FROM BD_SIRIM.dbo.RimPasaporte rp
				WHERE
					rp.sEstado = 'ENTREGADA'
	
			) rp2
			WHERE rp2.nFila >= @cantPas
		
		)
		AND rp3.sEstado = 'ENTREGADA'
	
), cte_pase_menos1año AS (

	SELECT 
		rp.*,
		[¿bPasMenos1Año?] = IIF(
								DATEDIFF(
									MM, 
									rp.dFechaEntrega,
									LEAD(rp.dFechaEntrega) OVER (PARTITION BY rp.sNumeroDNI ORDER BY rp.dFechaEntrega)
								) <= 11, -- ...
								1,
								0
							)
	FROM cte_pase_1mas rp
	
) SELECT * FROM cte_pase_menos1año p
WHERE 
	p.[¿bPasMenos1Año?] = 1
ORDER BY p.sNumeroDNI



/*░ Test
	-- 1
	00042828
	00053431
	00238702
	00240322
	00424148
	
	-- 2
	00049830
	00080515

	-- 3
	00227313
	00424513
*/

SELECT rp.sEstado, rp.dFechaEntrega FROM RimPasaporte rp
WHERE 
	rp.sEstado = 'ENTREGADA'
	AND rp.sNumeroDNI = '00238702'
ORDER BY rp.dFechaEntrega







-- ver 2.0: Resumen ...
;WITH cte_pase_menos1año AS (

	SELECT rp2.nAñoEntrega, rp2.nPas, rp2.nTotal FROM (
	
		SELECT
			rp.sNumeroDNI,
			[nAñoEntrega] = DATEPART(YYYY, rp.dFechaEntrega),
			[nPas] = COUNT(1),
			[nTotal] = COUNT(1)
		FROM BD_SIRIM.dbo.RimPasaporte rp
		WHERE
			rp.sEstado = 'ENTREGADA'
		GROUP BY
			rp.sNumeroDNI,
			DATEPART(YYYY, rp.dFechaEntrega)
		HAVING
			COUNT(1) > 1
	
	) rp2

) SELECT * FROM cte_pase_menos1año p
PIVOT (
	COUNT(p.[nTotal]) FOR p.[nAñoEntrega] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv


--======================================================================================================================================================