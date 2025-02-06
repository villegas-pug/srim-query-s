USE SIM
GO

/* »
	1. Calidad `SUSPENDIDA`: 301 | SUSPENDIDA ...
	2. Datos generales ...
	3. Tramites antes y después ...
	4. Datos de familiares ...
==============================================================================================================================================================*/

-- 1. Calidad `SUSPENDIDA` ...

-- 1.1 tmp de ultimo trámites `A` de CCM Suspendida ...
DROP TABLE IF EXISTS #tmp_ultimo_tram_ccm_suspendida
SELECT 
	tmp.*
	INTO #tmp_ultimo_tram_ccm_suspendida 
FROM (

	SELECT 
		st.uIdPersona,
		st.sNumeroTramite,
		[sTipoTramite] = stt.sDescripcion,
		[sCalidadMigratoria] = scm.sDescripcion,
		sti.sEstadoActual,
		st.dFechaHoraReg,
		sccm.dFechaAprobacion,
		sccm.dFechaVencimiento,
		[nFila_suspendida] = ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sccm.dFechaAprobacion DESC)
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	WHERE
		st.bCancelado = 0
		AND sti.sEstadoActual = 'A'
		-- AND st.nIdTipoTramite = 58 -- CCM
		AND sccm.nIdCalSolicitada = 301 -- SUSPENDIDA

) tmp
WHERE
	tmp.nFila_suspendida = 1

-- Test ...
SELECT COUNT(1) FROM #tmp_ultimo_tram_ccm_suspendida

-- 2. Datos generales ...
DROP TABLE IF EXISTS #tmp_ultimo_tram_ccm_suspendida_datos
SELECT 
	t_s.*,

	-- Datos ...
	sextr_t.sDomicilio,
	sextr_t.sTelefono,
	sextr_t.nEstatura,
	sextr_t.sEmail,
	sextr_t.dFechaEstadia,
	[sColorOjos] = sf_o_t.sDescripcion,
	[sColorCabello] = sf_c_t.sDescripcion,
	[sReligion] = sr_t.sDescripcion,
	[sOrganizacion] = so_t.sNombre,
	[sUbigeo] = su_t.sNombre,
	sextr_t.sCiudadNatal,
	[sCarnetActual] = CONCAT('''', sextr_t.sCarnetActual),
	[sProfesionOcupacion] = sprof_t.sDescripcion,
	[sPaisNacionalidad] = spnacio_t.sNacionalidad,
	[sPaisNacimiento] = spnacim_t.sNacionalidad
	INTO #tmp_ultimo_tram_ccm_suspendida_datos
FROM #tmp_ultimo_tram_ccm_suspendida t_s
JOIN SimPersona sper_t ON t_s.uIdPersona = sper_t.uIdPersona
LEFT JOIN SimExtranjero sextr_t ON t_s.uIdPersona = sextr_t.uIdPersona
LEFT JOIN SimReligion sr_t ON sextr_t.sIdReligion = sr_t.sIdReligion
LEFT JOIN SimOrganizacion so_t ON sextr_t.nIdOrganizacion = so_t.nIdOrganizacion
LEFT JOIN SimUbigeo su_t ON sextr_t.sIdUbigeoDomicilio = su_t.sIdUbigeo
LEFT JOIN SimProfesion sprof_t ON sextr_t.sIdProfesionOcupacion = sprof_t.sIdProfesion
LEFT JOIN SimFisonomia sf_o_t ON sextr_t.nIdColorOjos = sf_o_t.nIdFisonomia
LEFT JOIN SimFisonomia sf_c_t ON sextr_t.nIdColorCabello = sf_c_t.nIdFisonomia
LEFT JOIN SimPais spnacim_t ON sper_t.sIdPaisNacimiento = spnacim_t.sIdPais
LEFT JOIN SimPais spnacio_t ON sper_t.sIdPaisNacionalidad = spnacio_t.sIdPais

-- Test ...
SELECT COUNT(1) FROM #tmp_ultimo_tram_ccm_suspendida_datos
SELECT COUNT(1) FROM #tmp_ultimo_tram_ccm_suspendida

-- 3. Trámites antes y después ...
DROP TABLE IF EXISTS #tmp_ultimo_tram_ccm_suspendida_datos_todostram
SELECT 
	t_s.*,

	-- Otros trámites de inmigración ...
	[sNumeroTramite_Otros] = st_otros.sNumeroTramite,
	[sTipoTramite_Otros] = stt_otros.sDescripcion,
	[dFechaRegistro_Otros] = st_otros.dFechaHoraReg,
	[sEstadoTramite_Otros] = sti_otros.sEstadoActual
	INTO #tmp_ultimo_tram_ccm_suspendida_datos_todostram
FROM #tmp_ultimo_tram_ccm_suspendida_datos t_s
JOIN SimPersona sper_t ON t_s.uIdPersona = sper_t.uIdPersona
LEFT JOIN SimExtranjero sextr_t ON t_s.uIdPersona = sextr_t.uIdPersona
LEFT JOIN SimReligion sr_t ON sextr_t.sIdReligion = sr_t.sIdReligion
LEFT JOIN SimOrganizacion so_t ON sextr_t.nIdOrganizacion = so_t.nIdOrganizacion
LEFT JOIN SimUbigeo su_t ON sextr_t.sIdUbigeoDomicilio = su_t.sIdUbigeo
LEFT JOIN SimProfesion sprof_t ON sextr_t.sIdProfesionOcupacion = sprof_t.sIdProfesion
LEFT JOIN SimTramite st_otros ON t_s.uIdPersona = st_otros.uIdPersona
LEFT JOIN SimTramiteInm sti_otros ON st_otros.sNumeroTramite = sti_otros.sNumeroTramite
LEFT JOIN SimTipoTramite stt_otros ON st_otros.nIdTipoTramite = stt_otros.nIdTipoTramite
ORDER BY
	t_s.uIdPersona, st_otros.dFechaHoraReg

-- 4. Datos de familiares ...
DROP TABLE IF EXISTS #tmp_ultimo_tram_ccm_suspendida_datos_familiares
SELECT 
	t_s.*,

	-- Datos de familiares ...
	[sParentesco] = stp.sDescripcion,
	[sNombre_Familiar] = sf.sNombre,
	[sPriApe_Familiar] =sf.sPaterno,
	[sSegApe_Familiar] = sf.sMaterno,
	[sSexo_Familiar] = sf.sSexo,
	[dFecNac_Familiar] = sf.dFechaNacimiento,
	[sPaisNacionalidad_Familiar] = spnacio.sNombre,
	[sPaisNacimiento_Familiar] = spnacim.sNombre,
	[sCiudadNatal_Familiar] = sf.sCiudadNac,
	[sObservaciones_Familiar] = sf.sObservaciones

	INTO #tmp_ultimo_tram_ccm_suspendida_datos_familiares
FROM #tmp_ultimo_tram_ccm_suspendida_datos t_s
LEFT JOIN SimFamiliarExt sfe ON t_s.uIdPersona = sfe.uIdPersona
LEFT JOIN SimFamiliar sf ON sfe.nIdFamiliar = sf.nIdFamiliar
LEFT JOIN [dbo].[SimTipoParentesco] stp ON sfe.nIdParentesco = stp.nIdParentesco
LEFT JOIN [dbo].[SimDocFamiliar] sdf ON sf.nIdFamiliar = sdf.nIdFamiliar
LEFT JOIN SimPais spnacio ON sf.sIdPaisNacionalidad = spnacio.sIdPais
LEFT JOIN SimPais spnacim ON sf.sIdPaisNacionalidad = spnacim.sIdPais
ORDER BY
	t_s.uIdPersona

-- Test ...
SELECT * FROM #tmp_ultimo_tram_ccm_suspendida_datos_familiares

-- Final: ...
SELECT * FROM #tmp_ultimo_tram_ccm_suspendida_datos
SELECT * FROM #tmp_ultimo_tram_ccm_suspendida_datos_todostram
SELECT * FROM #tmp_ultimo_tram_ccm_suspendida_datos_familiares





-- Test ...
SELECT scm.sDescripcion, sper.* FROM SimPersona sper
JOIN #tmp_ultimo_tram_ccm_suspendida_datos s ON sper.uIdPersona = s.uIdPersona
JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
WHERE sper.uIdPersona = 'A6D1E5E7-AEDF-4524-BEF8-34BFC83BA4FB'

-- SimTramite
SELECT TOP 1 * FROM SimTramiteInm

SELECT TOP 10 * FROM SimArchivoPdf
SELECT TOP 10 * FROM [dbo].[SimSistCitaDireccion]
--==============================================================================================================================================================*/