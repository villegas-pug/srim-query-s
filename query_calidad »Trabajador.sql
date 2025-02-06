USE SIM
GO

-- STEP-01: CCM
-- 01.1: Ultima calidad migratoria aprobada...
DROP TABLE IF EXISTS #tmp_ccm_trab_ultima
SELECT 
	st.uIdPersona,
	[sCalidadMigratoria] = scm.sDescripcion,
	-- sti.sEstadoActual,
	-- st.dFechaHoraReg,
	[sDependencia] = sd.sNombre,
	st.dFechaHoraReg,
	[nAñoTramite] = CASE 
						WHEN DATEPART(YYYY, st.dFechaHoraReg) >= 2008 AND DATEPART(YYYY, st.dFechaHoraReg) <= 2011 THEN '2008-2011'
						WHEN DATEPART(YYYY, st.dFechaHoraReg) >= 2012 AND DATEPART(YYYY, st.dFechaHoraReg) <= 2014 THEN '2012-2014'
						WHEN DATEPART(YYYY, st.dFechaHoraReg) >= 2015 AND DATEPART(YYYY, st.dFechaHoraReg) <= 2017 THEN '2015-2017'
						WHEN DATEPART(YYYY, st.dFechaHoraReg) >= 2018 AND DATEPART(YYYY, st.dFechaHoraReg) <= 2020 THEN '2018-2020'
						WHEN DATEPART(YYYY, st.dFechaHoraReg) >= 2021 AND DATEPART(YYYY, st.dFechaHoraReg) <= 2023 THEN '2021-2023'
					END,
	sccm.dFechaAprobacion,
	[nIdOrganizacionCCM] = sti.nIdOrganizacion
	-- sccm.*,
	-- sti.*,
	-- sccm.dFechaVencimiento,
	INTO #tmp_ccm_trab_ultima
FROM SimTramite st
JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
WHERE
	st.bCancelado = 0
	AND st.nIdTipoTramite = 58 -- CCM
	AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND sti.sEstadoActual = 'A'
	AND scm.sDescripcion LIKE '%trabaj%'


-- index ...
CREATE NONCLUSTERED INDEX IX_tmp_ccm_trab_ultima_uIdPersona
    ON #tmp_ccm_trab_ultima(uIdPersona)


/*» Final
	→ Calidad `TRABAJADOR` 
===================================================================================================================*/
-- STEP-01: Union ...

-- 1.2: tmp_aux...
DROP TABLE IF EXISTS #tmp_aux_ext_permanentes
SELECT mm.* INTO #tmp_aux_ext_permanentes FROM (

	SELECT
		smm.uIdPersona,
		smm.dFechaControl,
		smm.sTipo,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.bTemporal = 0
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND smm.uIdPersona IN (SELECT DISTINCT ccm.uIdPersona FROM #tmp_ccm_trab_ultima ccm)

) mm
WHERE 
	mm.nFila_mm = 1

-- Index ...
CREATE INDEX IX_tmp_aux_ext_permanentes_uIdPersona
    ON dbo.#tmp_aux_ext_permanentes(uIdPersona)

-- Test: #tmp_aux_ext_permanentes
SELECT DISTINCT p.sTipo FROM #tmp_aux_ext_permanentes p

-- 1.3: Aux ...
DROP TABLE IF EXISTS #tmp_ccm_complementario
SELECT 
	ss.uIdPersona, 
	sc.sCentroTrabajo,
	ss.sRuc
	INTO #tmp_ccm_complementario
FROM SimComplementarioPDA sc
JOIN SimSituacionLaboralPDA ss ON sc.nIdCitaVerifica = ss.nIdCitaVerifica
WHERE 
	ss.uIdPersona IN (
		SELECT ccv.uIdPersona FROM #tmp_ccm_trab_ultima ccv
	)

-- Index ...
CREATE INDEX IX_tmp_ccm_complementario_uIdPersona
    ON dbo.#tmp_ccm_complementario(uIdPersona)

-- 1.4: ...
DROP TABLE IF EXISTS tmp_final_ccm
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

	[sEmpresa] = so.sNombre,

	-- [sDomicilioEmpresa] = sue.sNombre,
	-- [sDireccionEmpresa] = so.sDireccion,
	[sRuc] = so.sNumeroDoc,
	[dFechaControlMigratorio] = (
											SELECT e_p.dFechaControl FROM #tmp_aux_ext_permanentes e_p 
											WHERE 
												e_p.uIdPersona = f.uIdPersona
										),
	[¿Permanente?] = IIF(
								(
									SELECT e_p.sTipo FROM #tmp_aux_ext_permanentes e_p 
									WHERE 
										e_p.uIdPersona = f.uIdPersona
								) = 'E', 
								'Si', 
								'No'
							),
	[¿Perdió Calidad?]= IIF(
									(
										SELECT e_p.sTipo FROM #tmp_aux_ext_permanentes e_p WHERE e_p.uIdPersona = f.uIdPersona
									) = 'S',
									IIF(DATEDIFF(DD, (SELECT e_p.dFechaControl FROM #tmp_aux_ext_permanentes e_p WHERE e_p.uIdPersona = f.uIdPersona), GETDATE()) >= 183, 
										'Si',
										'No'
									),
									'Permanente'
								)

	INTO tmp_final_ccm
FROM #tmp_ccm_trab_ultima f 
JOIN SimPersona sp ON f.uIdPersona = sp.uIdPersona
LEFT JOIN SimExtranjero spe ON sp.uIdPersona = spe.uIdPersona
LEFT JOIN SimUbigeo su ON spe.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT JOIN SimOrganizacion so ON f.nIdOrganizacionCCM = so.nIdOrganizacion
LEFT JOIN SimUbigeo sue ON so.sIdUbigeo = sue.sIdUbigeo
LEFT JOIN SimProfesion sprof ON spe.sIdProfesionOcupacion = sprof.sIdProfesion

-- Test ...
SELECT * FROM tmp_final_ccm ccm 

SELECT COUNT(1) FROM tmp_final_ccm ccm WHERE ccm.[¿Perdió Calidad?] = 'Si'
--===================================================================================================================*/


-- Aux OTIC
select * from SimTramite where uIdPersona='25D39219-7A0A-45ED-A1E7-8F941253DEA7' order by dFechaHora desc 
SELECT * FROM SimTramite st  WHERE ST.sNumeroTramite ='LM230163965'
SELECT * FROM SimTramiteInm sti  WHERE sti.sNumeroTramite ='LM230163965' 
SELECT * FROM SimEvaluarTramiteInm seti WHERE seti.sNumeroTramite ='LM230163965'
SELECT * FROM SimExtranjero SE WHERE SE.uIdPersona='25D39219-7A0A-45ED-A1E7-8F941253DEA7'
SELECT * FROM SimCambioCalMig WHERE sNumeroTramite ='LM230163965'
SELECT * FROM SimEvaluarTramiteInmDetalleMetaData setidmd WHERE setidmd.nIdDetRequisito =9366599
SELECT * FROM SimOrganizacion WHERE nIdOrganizacion=49330
SELECT * FROM SimOrganizacion WHERE nIdOrganizacion=12429