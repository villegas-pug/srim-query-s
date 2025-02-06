USE SIM
GO

-- =========================================================================================================
-- ► ...
-- 301 | SUSPENDIDA
-- SELECT * FROM SimCalidadMigratoria scm WHERE scm.sDescripcion LIKE '%sus%'
-- =========================================================================================================

-- SimPersona: ...
-- =========================================================================================================
DROP TABLE IF EXISTS #per_calmigra_suspendida
SELECT 
	sp.uIdPersona,
	[sNumeroTramite] = sp.sNumDocIdentidad,
	scm.nIdCalidad,
	scm.sDescripcion [sCalidadMigratoria],
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaHoraAud,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad
	INTO #per_calmigra_suspendida
FROM SimPersona sp
JOIN SimCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
WHERE 
	sp.sIdPaisNacionalidad != 'PER'
	AND sp.nIdCalidad = 301

CREATE NONCLUSTERED INDEX #per_calmigra_suspendida_uIdPersona
ON #per_calmigra_suspendida(uIdPersona)
-- =========================================================================================================

-- ► SimMovMigra
-- =========================================================================================================
DROP TABLE IF EXISTS #mm_calmig_suspendida
SELECT
	DISTINCT
	mm.uIdPersona
	INTO #mm_calmig_suspendida
FROM (
	SELECT 
		smm.uIdPersona
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.sIdPaisNacionalidad != 'PER'
		AND smm.nIdCalidad = 301 --Suspendida
) mm

DROP TABLE IF EXISTS #mm_calmig_suspendida_result
SELECT 
	mm.uIdPersona, 
	[sNumeroTramite] = mm.sIdMovMigratorio,
	mm.nIdCalidad,
	[sCalidadMigratoria] = scm.sDescripcion,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	[dFechaControl] = mm.dFechaControl,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad
	INTO #mm_calmig_suspendida_result
FROM (
	SELECT 
		smm.*,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC) nRow_mm
	FROM SimMovMigra smm
	JOIN #mm_calmig_suspendida sus ON smm.uIdPersona = sus.uIdPersona
) mm
JOIN SimCalidadMigratoria scm ON mm.nIdCalidad = scm.nIdCalidad
JOIN SimPersona sp ON mm.uIdPersona = sp.uIdPersona
WHERE
	mm.nRow_mm = 1
	AND mm.nIdCalidad = 301
-- ========================================================================================================================

-- SimTramite ...
-- ========================================================================================================================

DROP TABLE IF EXISTS #per_tram_suspendida
SELECT 
	tram.uIdPersona, 
	[sNumeroTramite] = tram.sNumeroTramite,
	tram.nIdCalidadTramite,
	[sCalidadMigratoria] = tram.sCalidadTramite,
	tram.sNombre,
	tram.sPaterno,
	tram.sMaterno,
	tram.sSexo,
	tram.dFechaAprobacion,
	tram.sIdPaisNacimiento,
	tram.sIdPaisNacionalidad
	INTO #per_tram_suspendida
FROM (
	SELECT
		sp.*,
		st.sNumeroTramite,
		sccm.dFechaAprobacion,
		[nIdCalidadTramite] = scm.nIdCalidad,
		[sCalidadTramite] = scm.sDescripcion,
		ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sccm.dFechaAprobacion DESC)nRow_tram
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	WHERE
		sti.sEstadoActual = 'A'
		AND sp.sIdPaisNacionalidad != 'PER'
		AND sccm.nIdCalSolicitada = 301 --Suspendida
) tram
WHERE
	tram.nRow_tram = 1
-- ========================================================================================================================

-- Final: Union All
-- ========================================================================================================================
SELECT 
	calsus_final.* 
FROM (
	SELECT 
		calsus.*,
		ROW_NUMBER() OVER (PARTITION BY calsus.uIdPersona ORDER BY calsus.dFechaHoraAud DESC) nRow_calsus
	FROM (
		SELECT * FROM #per_calmigra_suspendida
		UNION
		SELECT * FROM #mm_calmig_suspendida_result
		UNION
		SELECT * FROM #per_tram_suspendida
	) calsus
) calsus_final
WHERE 
	calsus_final.nRow_calsus = 1
-- ========================================================================================================================


SELECT * FROM SimTramite st WHERE st.uIdPersona = 'D742D9AD-AA38-4357-99D6-00A082E3E9A4'
SELECT * FROM SimTramite st WHERE st.uIdPersona = 'A3354625-5374-45DB-B0E1-0187F72A2570'
SELECT * FROM SimTramite st WHERE st.uIdPersona = '657A89B1-83D0-420E-AABE-FA7A60ED03C5'

SELECT sti.sEstadoActual, * FROM SimCambioCalMig sccm 
JOIN SimTramiteInm sti ON sccm.sNumeroTramite= sti.sNumeroTramite
WHERE sccm.sNumeroTramite = 'LM180076111'
SELECT * FROM SimPersona sp WHERE sp.uIdPersona = '657A89B1-83D0-420E-AABE-FA7A60ED03C5'

