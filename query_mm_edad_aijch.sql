USE SIM
GO

-- 1
SELECT pv.*
FROM (

   SELECT

      [Año] = DATEPART(YYYY, smm.dFechaControl),
      [Mes] = DATEPART(MM, smm.dFechaControl),
		[Tipo Mov] = (
                        CASE smm.sTipo
                           WHEN 'S' THEN 'SALIDA'
                           WHEN 'E' THEN 'ENTRADA'
                        END
      ),
		[Rango Edad] = CASE 
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 0 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 17 THEN '0 - 17'
							ELSE '18 a más'
						END,
		[Ciudadano] = (
							CASE 
								WHEN smm.sIdPaisNacionalidad = 'PER' THEN 'PERUANO'
								ELSE 'EXTRANJERO'
							END
		),
		smm.uIdPersona

	FROM SimMovMigra smm
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	WHERE 
		smm.bAnulado = 0
		AND smm.bTemporal = 0
      -- AND smm.sIdDependencia = '27' -- 27 → A.I.J.CH.
		-- 37 → PCF SANTA ROSA IQUITOS
		-- 66 → STA. ROSA
      AND smm.sIdDependencia IN ('66') -- 66 → STA. ROSA
		AND smm.dFechaControl BETWEEN '2017-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
	
) mm2
PIVOT (
   COUNT(mm2.uIdPersona) FOR mm2.[Mes] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- Test

-- 1
SELECT * 
FROM SimDependencia d
WHERE
	d.bActivo = 1
	AND d.sNombre LIKE '%rosa%'

-- 2
SELECT
	smm.sIdDependencia,
	COUNT(1)
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE 
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.sIdDependencia IN ('37', '66') -- 37 → PCF SANTA ROSA IQUITOS
	AND smm.dFechaControl BETWEEN '2017-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
GROUP BY
	smm.sIdDependencia
ORDER BY 2 DESC