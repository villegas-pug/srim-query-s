USE SIM
GO

-- STEP-01: 59 | CAMBIO DE CLASE DE VISA | CCV
SELECT * FROM SimTipoTramite stt
WHERE
	stt.sDescripcion LIKE '%visa%'

SELECT 
	st.nIdTipoTramite,
	stt.sDescripcion,
	COUNT(1)
FROM SimTramite st
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE 
	st.nIdTipoTramite IN (31, 43, 54, 59, 101)
GROUP BY st.nIdTipoTramite, stt.sDescripcion

ORDER BY st.dFechaHoraReg DESC

-- 01.1: Ultima calidad migratoria aprobada...
DROP TABLE IF EXISTS #tmp_ccv_trab_ultima
SELECT * INTO #tmp_ccv_trab_ultima FROM (

	SELECT 
		st.uIdPersona,
		[sCalidadMigratoria] = scm.sDescripcion,
		-- sti.sEstadoActual,
		-- st.dFechaHoraReg,
		sti.dFechaFin,
		[nIdOrganizacionVisa] = sti.nIdOrganizacion,
		-- sccm.*,
		-- sti.*,
		-- sccm.dFechaVencimiento,
		[nFila_ccv] = ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY st.dFechaHoraReg DESC)
	FROM SimTramite st
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON scm.nIdCalidad = sp.nIdCalidad
	/*JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite*/
	WHERE
		st.nIdTipoTramite IN (
			31,
			43,
			59,
			101
		)
		AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND sti.sEstadoActual = 'A'
		AND scm.sDescripcion LIKE '%traba%'

) ccv
WHERE
	ccv.nFila_ccv = 1

-- index ...
CREATE NONCLUSTERED INDEX IX_tmp_ccv_trab_ultima_uIdPersona
    ON #tmp_ccv_trab_ultima(uIdPersona)




/*» Final
	→ Calidad `TRABAJADOR` 
===================================================================================================================*/
-- STEP-01: Union ...


-- 1.2: tmp_aux...
DROP TABLE IF EXISTS #tmp_aux_ext_permanentes
SELECT mm.uIdPersona INTO #tmp_aux_ext_permanentes FROM (

	SELECT
		smm.uIdPersona,
		smm.sTipo,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.sIdPaisNacionalidad != 'PER'
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'

) mm
WHERE 
	mm.nFila_mm = 1
	AND mm.sTipo = 'E'

-- Index ...
CREATE INDEX IX_#tmp_aux_ext_permanentes_uIdPersona
    ON dbo.#tmp_aux_ext_permanentes(uIdPersona)

-- 1.3: Aux ...
DROP TABLE IF EXISTS #tmp_ccv_complementario
SELECT 
	ss.uIdPersona, 
	sc.sCentroTrabajo,
	ss.sRuc
	INTO #tmp_ccv_complementario
FROM SimComplementarioPDA sc
JOIN SimSituacionLaboralPDA ss ON sc.nIdCitaVerifica = ss.nIdCitaVerifica
WHERE 
	ss.uIdPersona IN (
		SELECT ccv.uIdPersona FROM #tmp_ccv_trab_ultima ccv
	)

-- Index ...
CREATE INDEX IX_tmp_ccv_complementario_uIdPersona
    ON dbo.#tmp_ccv_complementario(uIdPersona)

-- 1.4: ...
DROP TABLE IF EXISTS #tmp_final_ccv
SELECT 

	f.*,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	[sDocumento] = sp.sIdDocIdentidad,
	sp.sNumDocIdentidad,
	spe.sTelefono,
	spe.sEmail,
	spe.sDomicilio,
	[sDomicilioPersona] = su.sNombre,
	[sProfesion] = sprof.sDescripcion,

	[sEmpresa] = ISNULL(so.sNombre, '-'),

	[sDomicilioEmpresa] = sue.sNombre,
	[sDireccionEmpresa] = so.sDireccion,
	[sRuc] = so.sNumeroDoc,
	[¿Permanente?] = IIF(
		EXISTS(SELECT 1 FROM tmp_aux_ext_permanentes e_p WHERE e_p.uIdPersona = f.uIdPersona), 'Si', 'No'
	)

	INTO #tmp_final_ccv
FROM #tmp_ccv_trab_ultima f 
JOIN SimPersona sp ON f.uIdPersona = sp.uIdPersona
LEFT JOIN SimExtranjero spe ON sp.uIdPersona = spe.uIdPersona
LEFT JOIN SimUbigeo su ON spe.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT JOIN SimOrganizacion so ON f.nIdOrganizacionVisa = so.nIdOrganizacion
LEFT JOIN SimUbigeo sue ON so.sIdUbigeo = sue.sIdUbigeo
LEFT JOIN SimProfesion sprof ON spe.sIdProfesionOcupacion = sprof.sIdProfesion

-- Test ...
SELECT * FROM #tmp_final_ccv

-- Index ...
CREATE NONCLUSTERED INDEX IX_SimOrganizacion_sNumeroDoc
    ON dbo.SimOrganizacion(sNumeroDoc)

CREATE NONCLUSTERED INDEX IX_SimSituacionLaboralPDA_uIdPersona
    ON dbo.SimSituacionLaboralPDA(uIdPersona)

CREATE NONCLUSTERED INDEX IX_SimSituacionLaboralPDA_nIdCitaVerifica
    ON dbo.SimSituacionLaboralPDA(nIdCitaVerifica)

CREATE NONCLUSTERED INDEX IX_SimComplementarioPDA_nIdCitaVerifica
    ON dbo.SimComplementarioPDA(nIdCitaVerifica)

-- Test ...
SELECT * FROM #tmp_final_ccv

SELECT * FROM SimOrganizacion so
WHERE so.sNombre LIKE '%PRELATURA%'

--===================================================================================================================*/