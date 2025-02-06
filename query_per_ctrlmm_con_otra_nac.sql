
-- ============================================================================================================
-- uIdPersona								sPaterno				sMaterno			sNombre				 --
-- 85129BFB-75D9-4846-8ACD-C591992E9D63		SAN MIGUEL WONG								ANYELL KATHERINE	 --
-- B0D0C092-7730-40B2-BB2C-75E1E2B26819		SAN MIGUEL				WONG				ANYELL KATHERINE     --
-- ============================================================================================================

/*► STEP-01: Extrae PAS `PER`; Entregado o Revalidados */
-- ============================================================================================================
DROP TABLE IF EXISTS #pas_per_e
SELECT 
	spas.*
	INTO #pas_per_e
FROM SimPasaporte spas
WHERE 
	spas.sEstadoActual IN ('E', 'R') -- Entregado | Revalidado
	AND spas.sIdPaisNacimiento = 'PER'
	-- Caracteristicas de PAS-E ...
	AND LEN(spas.sPasNumero) = 9
	AND spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (spas.sPasNumero LIKE '11%' OR spas.sPasNumero LIKE '12%')

/*► Add index `#pas_per_e` ...*/
CREATE NONCLUSTERED INDEX pas_per_e_sPasNumero
ON #pas_per_e(sPasNumero)
-- ============================================================================================================

/*► STEP-02: Extrae movmigra de PAS Peruanos, que realizaron el ctrlmig con otra nacionalidad ...  */
-- ============================================================================================================
-- SELECT TOP 1000 * FROM #mm_nac_per
DROP TABLE IF EXISTS #mm_nac_per
SELECT 
	DISTINCT 
	mm_per.sPasNumero,
	mm_per.dFechaNacimiento
	INTO #mm_nac_per
FROM (
	SELECT 
		spas.sPasNumero,
		spas.dFechaNacimiento
	FROM SimMovMigra smm
	JOIN #pas_per_e spas ON smm.sNumeroDoc = spas.sPasNumero
	WHERE
		smm.sIdPaisNacionalidad = 'PER'
) mm_per

/*► Add index `#mm_per_con_otra_nac` ...*/
CREATE NONCLUSTERED INDEX #mm_nac_per_sPasNumero_dFechaNacimiento
ON #mm_nac_per(sPasNumero, dFechaNacimiento)
-- ============================================================================================================

/*► Helper: tmp_MovMigra ... */
SELECT 
	smm.*,
	sp.dFechaNacimiento
	INTO #movmig 
FROM SimMovMigra smm
JOIN #mm_nac_per nac ON smm.sNumeroDoc = nac.sPasNumero
JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona

/*► Add index `#mm_per_con_otra_nac` ...*/
CREATE NONCLUSTERED INDEX #movmig
ON #movmig(sNumeroDoc, dFechaNacimiento)

/*► STEP-03:  ...  */
-- ============================================================================================================
-- SELECT * FROM #mm_nac_ext
DROP TABLE IF EXISTS #mm_nac_ext
SELECT 
	*
	INTO #mm_nac_ext
FROM (
	SELECT
		mmp.*,
		[mm_ext] = (SELECT COUNT(1) FROM #movmig mm 
					WHERE mm.sNumeroDoc = mmp.sPasNumero 
					AND mm.dFechaNacimiento = mmp.dFechaNacimiento
					AND mm.sIdPaisNacionalidad != 'PER')
	FROM #mm_nac_per mmp
) mme
WHERE mme.mm_ext > 0


/*► Add index `#mm_per_con_otra_nac` ...*/
CREATE NONCLUSTERED INDEX #mm_nac_ext_sPasNumero
ON #mm_nac_ext(sPasNumero)
-- ============================================================================================================

/*► FINAL: ...  */
-- ============================================================================================================
--DROP TABLE IF EXISTS #mm_per_con_otra_nac
SELECT 
	sper.uIdPersona,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.dFechaNacimiento,
	mm.sIdDocumento,
	mm.sNumeroDoc [sPasNumero],
	mm.sIdPaisNacimiento,
	mm.sIdPaisNacionalidad,
	mm.dFechaControl,
	mm.sTipo,
	mm.sIdPaisMov
	--INTO #mm_per_con_otra_nac
FROM #mm_nac_ext mne
JOIN #movmig mm ON mne.sPasNumero = mm.sNumeroDoc AND mne.dFechaNacimiento = mm.dFechaNacimiento
JOIN SimPersona sper ON mm.uIdPersona = sper.uIdPersona
/*WHERE
	--mne.sPasNumero = '116319777'*/
ORDER BY 
	sper.sNombre, sper.sPaterno, sper.sMaterno, sper.dFechaNacimiento,  mm.dFechaControl DESC

/*► Clean-up ... */
DROP TABLE IF EXISTS #pas_per_e
DROP TABLE IF EXISTS #per_con_otra_nac
DROP TABLE IF EXISTS #mm_per_con_otra_nac

/*► test ...*/
--SELECT TOP 10000 * FROM #mm_per_con_otra_nac smm ORDER BY smm.sNumeroDoc
-- ============================================================================================================

/*► Test ...*/
SELECT 
	/*sp.sIdPaisNacionalidad, 
	sp.sIdPaisNacimiento,
	sp.sIdPaisResidencia,*/
	smm.* 
FROM SimPersona sp
JOIN  SimMovMigra smm ON smm.uIdPersona = sp.uIdPersona
--JOIN SimPasaporte spas ON smm.sNumeroDoc = spas.sPasNumero
--LEFT OUTER JOIN SimDocPersona sdp ON sp.uIdPersona = sdp.uIdPersona
WHERE 
	-- sp.sNombre LIKE 'ANYELL%'
	-- AND sp.sPaterno LIKE 'SAN MIGUEL%'
	sp.sNombre LIKE 'ann%'
	AND sp.sPaterno LIKE 'fernan%'
	AND sp.sMaterno LIKE 'palom%'
ORDER BY smm.dFechaControl DESC

	 

	
SELECT * FROM SimPersona sper WHERE sper.uIdPersona = '3CC2EE62-F876-4328-A1B9-08A1D47720D9'
SELECT * FROM SimPasaporte spas WHERE spas.sPasNumero = '118558064'

SELECT * FROM SimMovMigra smm WHERE smm.sNumeroDoc = '119156641'
