USE SIM
GO

/*=========================================================================================================================================================
░ RESIDENTES
--=========================================================================================================================================================*/

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimResidentes

-- STEP-01: `tmp` Extranjeros permanecen en Perú ...
DROP TABLE IF EXISTS #cte_ctrlmigra
SELECT 
	smm.*
	INTO #cte_ctrlmigra
FROM (
		
	SELECT 
		smm.uIdPersona,
		[dFechaMovMigra] = smm.dFechaControl,
		[nIdCalidad] = smm.nIdCalidad,
		[nFila_MovMigra] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC),
		[sTipoMovMigra] = smm.sTipo
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad != 'PER'

) smm
WHERE
	smm.nFila_MovMigra = 1
	AND smm.sTipoMovMigra = 'E'

-- Index ...
CREATE NONCLUSTERED INDEX ix_#cte_ctrlmigra_uIdPersona
    ON #cte_ctrlmigra(uIdPersona)


-- STEP-02: Final ...
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimResidentes
;WITH cte_ccm AS (-- `tmp` Extranjeros solicitaron CCM ...

	SELECT * FROM (

		SELECT 
			st.uIdPersona,
			[dFechaAprobacion] = sti.dFechaFin,
			[nIdCalidad] = scm.nIdCalidad,
			[nFila_CCM] = ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sti.dFechaFin DESC)
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
		JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
		WHERE
			st.nIdTipoTramite = 58 -- CCM
			-- AND sti.dFechaFin >= '2016-01-01 00:00:00.000'
			AND st.dFechaHoraReg >= '2016-01-01 00:00:00.000'
			-- AND scm.sTipo = 'R'
			AND EXISTS(-- 6 | IMPRESION
		
					SELECT TOP 1 1 FROM SimEtapaTramiteInm seti
					WHERE
						seti.sNumeroTramite = st.sNumeroTramite
						AND seti.nIdEtapa = 6
						AND seti.bActivo = 1
						-- AND seti.sEstado = 'F'
	
			)

	) ccm
	WHERE 
		ccm.nFila_CCM = 1

), cte_ccm_res AS (-- Solicitaron CCM, registran CM y permanecen en Perú ...

	SELECT ccm.* FROM cte_ccm ccm
	JOIN #cte_ctrlmigra cm ON ccm.uIdPersona = cm.uIdPersona

), cte_residentes AS (-- Residentes ...

	SELECT 
		res_f2.uIdPersona,
		res_f2.dFechaMovMigra,
		res_f2.nIdCalidad
	FROM (

		SELECT 
			res_f1.*,
			[nFila_res] = ROW_NUMBER() OVER (PARTITION BY res_f1.uIdPersona ORDER BY res_f1.dFechaMovMigra DESC)
		FROM (

			SELECT 
				cm.uIdPersona,
				cm.dFechaMovMigra,
				cm.nIdCalidad
			FROM #cte_ctrlmigra cm
			UNION ALL
			SELECT 
				ccm.uIdPersona,
				ccm.dFechaAprobacion,
				ccm.nIdCalidad
			FROM cte_ccm ccm
		
		) res_f1
	
	) res_f2
		WHERE
			res_f2.nFila_res = 1

) SELECT 
		res.uIdPersona,
		sp.sSexo,
		sp.dFechaNacimiento,
		sp.sIdPaisNacionalidad,
		[dFechaAprobacion] = res.dFechaMovMigra,
		res.nIdCalidad
		INTO BD_SIRIM.dbo.RimResidentes
	FROM cte_residentes res
	JOIN SimPersona sp ON res.uIdPersona = sp.uIdPersona


-- Test ...

SELECT * FROM BD_SIRIM.dbo.RimResidentes

SELECT 
	seti.*
FROM SimEtapaTramiteInm  seti
JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
WHERE
	seti.sNumeroTramite = 'LM220089287'

--=========================================================================================================================================================

SELECT TOP 100 * FROM SimProrroga