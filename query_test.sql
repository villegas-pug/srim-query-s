USE SIM
GO

-- =========================================================================================================
-- ► ...
-- 301 | SUSPENDIDA
-- SELECT * FROM SimCalidadMigratoria scm WHERE scm.sDescripcion LIKE '%sus%'
-- =========================================================================================================


-- MovMigra: Obtener la calidad `Suspendida` por el movimiento migratorio ...

-- ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC) nRow_mm
DROP TABLE IF EXISTS #mm_per_suspendida
SELECT
	DISTINCT
	mm.uIdPersona
	INTO #mm_per_suspendida
FROM (
	SELECT 
		smm.uIdPersona
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.sIdPaisNacionalidad != 'PER'
		AND smm.nIdCalidad = 301 --Suspendida
) mm


-- STEP-02
DROP TABLE IF EXISTS #mm_calmig_suspendida2
SELECT 
	mm.*
	INTO #mm_calmig_suspendida2
FROM (
	SELECT 
		smm.*,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC) nRow_mm
	FROM SimMovMigra smm
	JOIN #mm_per_suspendida sus ON smm.uIdPersona = sus.uIdPersona
) mm
WHERE
	mm.nRow_mm = 1
	AND mm.nIdCalidad = 301

/*» Test ... */
SELECT * FROM #mm_calmig_suspendida2
SELECT * FROM SimMovMigra WHERE uIdPersona = 'CF70342B-8EAC-40D1-87E6-755062F41F63' ORDER BY dFechaControl DESC




-- SimTramite ...
DROP TABLE IF EXISTS #mm_per_tram_suspendida
SELECT 
	tram.* 
	INTO #mm_per_tram_suspendida
FROM (
	SELECT
		st.sNumeroTramite,
		sp.*,
		[sCalidadMigratoria] = scm.sDescripcion,
		ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY st.dFechaHoraAud DESC)nRow_tram
	FROM SimTramite st
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	WHERE
		sp.sIdPaisNacionalidad != 'PER'
		AND sccm.nIdCalSolicitada = 301 --Suspendida
) tram
WHERE
	tram.nRow_tram = 1

	