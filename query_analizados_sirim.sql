USE SIRIM
GO

SELECT * FROM MASDE2_PASAPORTES_2018_2022 p
WHERE
	p.sID_PERSONA_e = '7A71A961-E42B-41CB-928B-3A39D35BF4E9'


-- STEP-01: Total registros de `Multiples_DNIs_2_19ene_a`: 80, 000
SELECT COUNT(1) FROM Multiples_DNIs_2_19ene_a

-- STEP-02: Analizados → 68296
SELECT 
	/*[nAñoAnalisis] = YEAR(p.dFechaFin),
	[nMesAnalisis] = MONTH(p.dFechaFin),*/
	[nTotal] = COUNT(1)
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
WHERE
	t.sNombre = 'Multiples_DNIs_2_19ene_a'
GROUP BY
	YEAR(p.dFechaFin),
	MONTH(p.dFechaFin)
ORDER BY
	[nMesAnalisis]


-- STEP-02: Asignados → 69,327 ...
SELECT 
	/*[nAñoAsig] = YEAR(a.dFechaAsignacion),
	[nMesAsig] = MONTH(a.dFechaAsignacion),*/
	[nTotalAsig] = SUM((a.nRegAnalisisFin - a.nRegAnalisisIni) + 1)
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
WHERE
	t.sNombre = 'Multiples_DNIs_2_19ene_a'
GROUP BY
	YEAR(a.dFechaAsignacion),
	MONTH(a.dFechaAsignacion)
ORDER BY
	[nMesAsig]

-- SELECT COUNT(1) FROM Multiples_DNIs_2_19ene_a
-- SELECT * FROM Multiples_DNIs_2_19ene_a
-- Test ...


SELECT 
	/*
	[nAñoAsig] = YEAR(a.dFechaAsignacion),
	[nMesAsig] = MONTH(a.dFechaAsignacion),
	[nTotalAsig] = SUM((a.nRegAnalisisFin - a.nRegAnalisisIni) + 1)
	*/
	-- dni.*
	-- p.nIdRegistroAnalisis
	[nIdRegistroAnalisis] = p.nIdRegistroAnalisis,
	[nIdDNI] = dni.nId
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
RIGHT OUTER JOIN Multiples_DNIs_2_19ene_a dni ON p.nIdRegistroAnalisis = dni.nId
WHERE
	t.sNombre = 'Multiples_DNIs_2_19ene_a'
ORDER BY
	p.nIdRegistroAnalisis

GROUP BY
	YEAR(a.dFechaAsignacion),
	MONTH(a.dFechaAsignacion)
ORDER BY
	[nMesAsig]

-- Test 
SELECT TOP 100 * FROM Multiples_DNIs_2_19ene_a dni
JOIN Multiples_DNIs_2_19ene_a dni2 ON dni.nId = dni2.nId
RIGHT JOIN (
	SELECT [nId] FROM (
		VALUES
			(80001),
			(80002),
			(80003)
	) AS tmp(nId)
) tmp ON tmp.nId = dni.nId

