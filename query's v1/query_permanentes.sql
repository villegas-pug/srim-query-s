USE SIM
GO

/*░
-- ...
-- USA | EE.UU | ESTADOUNIDENSE
========================================================================================================================================================*/

-- » Por `uIdPersona` → `48,150`
;WITH tmp_ctrlmig_permanentes AS (

	SELECT * FROM (

		SELECT 
			[dFechaControl] = CONVERT(DATE, smm.dFechaControl),
			[sTipoControl] = smm.sTipo,
			[sProc/Destino] = smm.sIdPaisMov,
			sper.sNombre,
			sper.sPaterno,
			sper.sMaterno,
			[sSexo] = sper.sSexo,
			[dFechaNacimiento] = sper.dFechaNacimiento,
			[sNacionalidad] = sp.sNombre,
			[sCalidad/MovMig] = scmov.sDescripcion,
			[sCalidad/Per] = scper.sDescripcion,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
		JOIN SimCalidadMigratoria scper ON sper.nIdCalidad = scper.nIdCalidad
		JOIN SimCalidadMigratoria scmov ON smm.nIdCalidad = scmov.nIdCalidad
		JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
		WHERE
			smm.bAnulado = 0
			AND smm.sTipo IN ('E', 'S')
			-- AND smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Solo extranjeros ...
			AND smm.sIdPaisNacionalidad = 'USA'
			-- AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

	) mm
	WHERE
		mm.nFila_mm = 1
		AND mm.sTipoControl = 'E'

) SELECT COUNT(1) FROM tmp_ctrlmig_permanentes
	
-- » Por `SNumeroDocumento` | `dFechanacimiento` → ``
;WITH tmp_ctrlmig_permanentes AS (

	SELECT * FROM (

		SELECT 
			[dFechaControl] = CONVERT(DATE, smm.dFechaControl),
			[sTipoControl] = smm.sTipo,
			[sProc/Destino] = smm.sIdPaisMov,
			sper.sNombre,
			sper.sPaterno,
			sper.sMaterno,
			[sSexo] = sper.sSexo,
			[dFechaNacimiento] = sper.dFechaNacimiento,
			[sNacionalidad] = sp.sNombre,
			[sCalidad/MovMig] = scmov.sDescripcion,
			[sCalidad/Per] = scper.sDescripcion,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM SimMovMigra smm
		JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
		JOIN SimCalidadMigratoria scper ON sper.nIdCalidad = scper.nIdCalidad
		JOIN SimCalidadMigratoria scmov ON smm.nIdCalidad = scmov.nIdCalidad
		JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
		WHERE
			smm.bAnulado = 0
			AND smm.sTipo IN ('E', 'S')
			-- AND smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Solo extranjeros ...
			AND smm.sIdPaisNacionalidad = 'USA'
			AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

	) mm
	WHERE
		mm.nFila_mm = 1
		AND mm.sTipoControl = 'E'

) SELECT COUNT(1) FROM tmp_ctrlmig_permanentes


-- Test
SELECT * FROM SimPais sp
WHERE	
	sp.sIdPais LIKE '%usa%'

--========================================================================================================================================================