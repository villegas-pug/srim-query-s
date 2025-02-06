/*░
-- 
	→ Nombres| Apellido 1 | Apellido 2 | Sexo | Fecha de Nacimiento	| Nacionalidad 
===============================================================================================================*/

-- STEP-01: `tmp`
SELECT 
	TOP 0 
	[nId] = 0,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad
	INTO #tmp_2identidad
FROM SimPersona sp


-- STEP-02: Bulk ...
-- INSERT INTO #tmp_2identidad VALUES(
SELECT * FROM #tmp_2identidad

-- STEP-03: ...
SELECT 
	tmp.nId,
	sp.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	sm.sIdModulo,
	[sNombreModulo] = sm.sDescripcion
FROM SimPersona sp
RIGHT JOIN #tmp_2identidad tmp ON 
							sp.sNombre = tmp.sNombre 
							AND sp.sPaterno = tmp.sPaterno 
							AND sp.sMaterno = tmp.sMaterno 
							AND sp.sSexo = tmp.sSexo 
							AND sp.dFechaNacimiento = tmp.dFechaNacimiento
LEFT JOIN SimSesion ss ON sp.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
ORDER BY
	tmp.nId

-- ===============================================================================================================


