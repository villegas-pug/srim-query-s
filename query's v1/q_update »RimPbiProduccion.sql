USE SIRIM
GO

-- SELECT * FROM RimPbiProduccion

DROP TABLE IF EXISTS RimPbiProduccion
SELECT 
	[sLoginAnalista] = ua.sLogin,
	[usrAnalista] = ua.sNombres,
	[dFechaAnalisis] = p.dFechaFin,
	[sGrupo] = uc.sGrupo
	INTO RimPbiProduccion
FROM RimTablaDinamica t
JOIN SidUsuario uc ON t.uIdUsrCreador = uc.uIdUsuario
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
JOIN RimAsigGrupoCamposAnalisis a ON g.nIdGrupo = a.nIdGrupo
JOIN SidUsuario ua ON a.uIdUsrAnalista = ua.uIdUsuario
JOIN RimProduccionAnalisis p ON a.nIdAsigGrupo = p.nIdAsigGrupo
WHERE
	uc.sLogin != 'rguevarav'
	AND ua.sLogin NOT IN ('NPASTOR', 'EGOLIVERA', 'RGUEVARAV')
