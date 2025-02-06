USE SIM
GO

-- ░ Nacionalizados 
-- ========================================================================================================================================


-- STEP-01: 
DROP TABLE IF EXISTS #tmpctrlmigprevmovmigaux
SELECT 
	smm.uIdPersona,
	[Año Control] = DATEPART(YYYY, smm.dFechaControl),
	[Tipo Movimiento] = smm.sTipo,
	[Tipo Movimiento Prev] = LEAD(smm.sTipo) OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	INTO #tmpctrlmigprevmovmigaux
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0

-- STEP-02: ...
DROP TABLE IF EXISTS #tmpctrlmigprevmovmigaux_i
SELECT 
	smm.*
	INTO #tmpctrlmigprevmovmigaux_i
FROM #tmpctrlmigprevmovmigaux smm
WHERE
	smm.[Tipo Movimiento] = smm.[Tipo Movimiento Prev]

-- Index
CREATE INDEX ix_#tmpctrlmigprevmovmigaux_uIdPersona
    ON dbo.#tmpctrlmigprevmovmigaux_i(uIdPersona)

-- Test
-- SELECT TOP 10 * FROM #tmpctrlmigprevmovmigaux_i i ORDER BY i.[Año Control] DESC
SELECT TOP 10 * FROM SimMovMigra i
WHERE i.uIdPersona = '0C2638FF-9D0D-4E8B-A524-72E264905B94'
ORDER BY i.dFechaControl DESC

-- STEP-03: Final...
;WITH cte_final AS (

	SELECT 
		mm.uIdPersona,
		mm.[Año Control]
	FROM (

		SELECT 
			mm.*,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.[Año Control] DESC)
		FROM #tmpctrlmigprevmovmigaux_i mm

	) mm
	WHERE
		mm.nFila_mm = 1

) SELECT 
	f.[Año Control],
	[Total] = COUNT(1)
FROM cte_final f
WHERE f.[Año Control] >= 1990
GROUP BY f.[Año Control]
ORDER BY f.[Año Control]
	

-- Test
SELECT i.[Año Control] FROM #tmpctrlmigprevmovmigaux_i i GROUP BY i.[Año Control]
-- ========================================================================================================================================