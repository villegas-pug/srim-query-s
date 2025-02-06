	
/*=============================================================================================================================================
» SIMNAC
===============================================================================================================================================*/
SELECT
	[sNumeroTramite] = (st.sNumeroTramite),
	[sFechaTramite] = (st.dFechaHoraReg),
	[sEstadoTramite] = (stn.sEstadoActual),
	[sFechaAprobacion] = (stn.dFechaHoraAud),
	[sTipoTramite] = (stt.sDescripcion),
	[sBeneficiario] = (sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno),
	(sp.sSexo),
	(sp.dFechaNacimiento),
	(sp.sIdPaisNacionalidad),
	(sp.sIdPaisNacimiento),
	(sp.sIdPaisResidencia),
	spr.sIdProfesion,
	[sProfesion] = (spr.sDescripcion),
	se.sIdUbigeoDomicilio,
	se.sDomicilio
FROM SimTramite st
JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
LEFT JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
LEFT JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
LEFT JOIN SimProfesion spr ON sp.sIdProfesion = spr.sIdProfesion
WHERE
	stn.sEstadoActual IN ('A', 'P')
	AND stn.dFechaHoraAud >= '2016-01-01 00:00:00'
	AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)-- » Trámites de Nacionalización ...
	-- stn.nIdEtapaActual IN (6, 53, 40, 43, 44, 42, 48, 47)
	AND EXISTS (
	
		SELECT TOP 1 1 FROM SimEtapaTramiteNac setn
		WHERE
			setn.sNumeroTramite = st.sNumeroTramite
			AND setn.nIdEtapa = 6 -- Impresión
	
	)
--=============================================================================================================================================


/*=============================================================================================================================================
» SIMINM
===============================================================================================================================================*/
-- » PASO-01: 58 | CCM ...
SELECT * FROM SimCalidadMigratoria scm
WHERE scm.sSigla = 'CPP'

DROP TABLE IF EXISTS #tmp_ccm_1
SELECT
	sp.uIdPersona,
	(st.sNumeroTramite),
	[dFechaTramite] = (st.dFechaHoraReg),
	(sti.sEstadoActual),

	[dFechaAprobacion] = COALESCE(sccm.dFechaAprobacion, st.dFechaHoraAud, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `FechaAprob`. Si el estado es `P` la fecha del ultimo evento ...
	[dFechaVencimiento] = COALESCE(sccm.dFechaVencimiento, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `FechaVenc`.
	
	[dTipoTramite] = (stt.sDescripcion),
	[sCalidadMigratoria] = (scm.sDescripcion),
	[sTipoCalidad] = CASE (scm.sTipo)
							WHEN 'R' THEN 'RESIDENTE'
							WHEN 'T' THEN 'TEMPORAL'
							ELSE '-'
					 END,
	sBeneficiario = (sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno),
	sSexo = (sp.sSexo),
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	sp.sIdPaisNacimiento,
	sp.sIdPaisResidencia,
	[sProfesion] = spr.sDescripcion,
	se.sIdUbigeoDomicilio,
	se.sDomicilio
	INTO #tmp_ccm_1
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
LEFT JOIN SimProfesion spr ON sp.sIdProfesion = spr.sIdProfesion
LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
WHERE
	st.nIdTipoTramite = 58
	AND scm.sTipo = 'R' -- Tipo Calidad `Residente`
	AND sti.sEstadoActual IN ('A', 'P')
	AND sti.nIdEtapaActual IN (-- Etapas posteriores a la pre-eval ...
		SELECT 
			se.nIdEtapa
		FROM SimEtapaTipoTramite sett
		JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
		WHERE 
			sett.nIdTipoTramite = 58 -- CCM
			AND sett.nSecuencia >= 4
	)
	AND st.dFechaHoraAud >= '2016-01-01 00:00:00.000'
	AND sp.sIdPaisNacionalidad NOT IN ('PER', 'NNN')

-- Index `tmp`
CREATE NONCLUSTERED INDEX ix_tmp_ccm_1_uIdPersona
    ON #tmp_ccm_1(uIdPersona)

/* ► PASO-02: Ordena registros por persona de manera descendente por fecha de aprobación del trámite ... */
-- SELECT * FROM #tmp_ccm_2
DROP TABLE IF EXISTS #tmp_ccm_2
SELECT * INTO #tmp_ccm_2
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY sccm.uIdPersona ORDER BY sccm.dFechaAprobacion DESC)nFila FROM #tmp_CCM_1 sccm) tmp
WHERE tmp.nFila = 1

CREATE NONCLUSTERED INDEX ix_tmp_ccm_2_uIdPersona
    ON #tmp_ccm_2(uIdPersona)

/*► Clean-up: `tmp's` ... */
-- ...


/*» PASO-03 ...*/
--DROP TABLE #tmp_CCM_3
--SELECT TOP 10 * FROM #tmp_CCM_3 
SELECT * INTO #tmp_CCM_3 
FROM(
	SELECT 
		sccm.*,
		[sTipoControl] = smm.sTipo,
		smm.dFechaControl,
		[sPaisMovimiento] = smm.sIdPaisMov,
		scm.nIdCalidad,
		[sCalidadMovimiento] = scm.sDescripcion,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)nFilaMovMig
	FROM #tmp_CCM_2 sccm
	JOIN SimMovMigra smm ON sccm.uIdPersona = smm.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
) tmp
WHERE tmp.nFilaMovMig = 1

/*» PASO-04: Opcional ... */ 
--SELECT * FROM #tmp_pv
--DROP TABLE #tmp_pv
SELECT * INTO #tmp_pv FROM (
	SELECT
		sccm.*,
		st.sNumeroTramite,
		st.dFechaHoraReg,
		st.nIdTipoTramite,
		ROW_NUMBER() OVER (PARTITION BY sccm.uIdPersona ORDER BY st.dFechaHoraReg DESC) nFila_pv
	FROM #tmp_CCM_3 sccm
	JOIN SimTramite st ON sccm.uIdPersona = st.uIdPersona
	WHERE
		st.nIdTipoTramite = 39 --Permiso de Viaje
		AND st.dFechaHoraReg <= sccm.dFechaControl
) tmp
WHERE tmp.nFila_pv = 1


/*» PASO-05: Resultado ...*/
--DROP TABLE #tmp_ccm_result
--SELECT TOP 10 * FROM #tmp_ccm_result
SELECT 
	sccm.*,
	pv.sNumeroTramite,
	pv.dFechaHoraReg,
	pv.nIdTipoTramite
	INTO #tmp_ccm_result
FROM #tmp_CCM_3 sccm
LEFT JOIN #tmp_pv pv ON sccm.uIdPersona = pv.uIdPersona
/*» ============================================================================================================================================================================================= */


/*» ================================================================== PRR =================================================================== */
/*» PASO-01 ... */
DROP TABLE IF EXISTS #tmp_prr_1
SELECT
	sp.uIdPersona,
	st.sNumeroTramite,
	[dFechaTramite] = st.dFechaHoraReg,
	sti.sEstadoActual,

	[dFechaAprobacion] = COALESCE(sti.dFechaFin, st.dFechaHoraAud, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `Fecha Fin`.
	[dFechaVencimiento] = COALESCE(spr.dFechaVencimiento, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `Fecha Venc`.

	[sTipoTramite] = stt.sDescripcion,
	[sCalidadMigratoria] = scm.sDescripcion,
	[sTipoCalidad] = CASE (spr.sTipo)
							WHEN 'R' THEN 'RESIDENTE'
							WHEN 'T' THEN 'TEMPORAL'
							ELSE '-'
					 END,
	[sBeneficiario] = (sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno),
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	sp.sIdPaisNacimiento,
	sp.sIdPaisResidencia,
	[sProfesion] = spro.sDescripcion,
	se.sIdUbigeoDomicilio,
	se.sDomicilio
	INTO #tmp_prr_1
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimProrroga spr ON sti.sNumeroTramite = spr.sNumeroTramite
JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
JOIN SimCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
LEFT JOIN SimProfesion spro ON sp.sIdProfesion = spro.sIdProfesion
LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
WHERE
	st.nIdTipoTramite = 57 -- PRR
	AND spr.sTipo = 'R'
	AND sti.sEstadoActual = 'A'
	AND st.dFechaHoraAud >= '2016-01-01 00:00:00.000'
	AND sp.sIdPaisNacionalidad NOT IN ('PER', 'NNN')

CREATE NONCLUSTERED INDEX ix_#tmp_prr_1_uIdPersona
    ON #tmp_prr_1(uIdPersona, Fecha_Aprobacion)

/*» PASO-02: Filtra registros por persona y fecha aprobación descendente ... */
DROP TABLE IF EXISTS #tmp_prr_2
SELECT * INTO #tmp_prr_2
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY dFechaAprobacion DESC)nFila FROM #tmp_prr_1) prr
WHERE prr.nFila = 1

CREATE NONCLUSTERED INDEX ix_#tmp_prr_2_uIdPersona
    ON #tmp_prr_2(uIdPersona)

/*» PASO-03 ... */
-- SELECT TOP 100 * FROM #tmp_PRR_3 
DROP TABLE IF EXISTS #tmp_PRR_3
SELECT * INTO #tmp_PRR_3 
FROM(
	SELECT
		prr.*,
		smm.sTipo Tipo_Control,
		smm.dFechaControl Fecha_Control,
		smm.sIdPaisMov Pais_Movimiento,
		scm.nIdCalidad Id_Calidad_Movimiento,
		scm.sDescripcion Calidad_Movimiento,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)nFilaMovMig
	FROM #tmp_PRR_2 prr
	JOIN SimMovMigra smm ON prr.uIdPersona = smm.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
) tmp
WHERE tmp.nFilaMovMig = 1

/*» PASO-04:Opcional ... */
--SELECT * FROM #tmp_pv
--DROP TABLE #tmp_pv
SELECT * INTO #tmp_pv FROM (
	SELECT
		prr.*,
		st.sNumeroTramite,
		st.dFechaHoraReg,
		st.nIdTipoTramite,
		ROW_NUMBER() OVER (PARTITION BY prr.uIdPersona ORDER BY st.dFechaHoraReg DESC) nFila_pv
	FROM #tmp_PRR_3 prr
	JOIN SimTramite st ON prr.uIdPersona = st.uIdPersona
	WHERE
		st.nIdTipoTramite = 39
		AND st.dFechaHoraReg <= prr.Fecha_Control
) tmp
WHERE tmp.nFila_pv = 1

/*» PASO-05: Resultado ...*/
--DROP TABLE #tmp_prr_result
SELECT 
	prr.*,
	pv.sNumeroTramite,
	pv.dFechaHoraReg,
	pv.nIdTipoTramite
	INTO #tmp_prr_result
FROM #tmp_PRR_3 prr
LEFT JOIN #tmp_pv pv ON prr.uIdPersona = pv.uIdPersona



/*=======================================================================================================================================================
► 113 | REGULARIZACION DE EXTRANJEROS
========================================================================================================================================================*/
/*» PASO-01 ... */
DROP TABLE IF EXISTS #tmp_re_1
SELECT
	sp.uIdPersona,
	(st.sNumeroTramite),
	[dFechaTramite] = (st.dFechaHoraReg),
	(sti.sEstadoActual)Estado_Tramite,

	[dFechaAprobacion] = COALESCE(sccm.dFechaAprobacion, st.dFechaHoraAud, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `FechaAprob`. Si el estado es `P` la fecha del ultimo evento ...
	[dFechaVencimiento] = COALESCE(sccm.dFechaVencimiento, '1900-01-01 00:00:00.000'), -- Si el estado es `A`, entonces tiene `FechaVenc`.

	[sTipoTramite] = stt.sDescripcion,
	[sCalidadMigratoria] = (scm.sDescripcion),
	[sTipoCalidad] = CASE (scm.sTipo)
							WHEN 'R' THEN 'RESIDENTE'
							WHEN 'T' THEN 'TEMPORAL'
							ELSE '-'
						END,
	[Beneficiario] = (sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno),
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	sp.sIdPaisNacimiento,
	sp.sIdPaisResidencia,
	[sProfesion] = spr.sDescripcion,
	se.sIdUbigeoDomicilio,
	se.sDomicilio
	INTO #tmp_re_1
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimEtapa seta ON sti.nIdEtapaActual = seta.nIdEtapa
JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
LEFT JOIN SimProfesion spr ON sp.sIdProfesion = spr.sIdProfesion
LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
WHERE
	st.nIdTipoTramite = 113 -- Regularización ...
	AND sti.sEstadoActual IN ('P', 'A')
	AND sti.nIdEtapaActual IN (
		SELECT 
			se.nIdEtapa
		FROM SimEtapaTipoTramite sett
		JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
		WHERE 
			sett.nIdTipoTramite = 113 -- Regularización
			AND sett.nSecuencia >= 3
	)
	AND st.dFechaHoraAud >= '2016-01-01 00:00:00.000'
	AND sp.sIdPaisNacionalidad NOT IN ('PER', 'NNN')

-- Index `tmp`
CREATE NONCLUSTERED INDEX ix_tmp_re_1_uIdpersona
ON #tmp_re_1(uIdpersona)

/*» PASO-02: Ordena registros por persona de manera descendente por fecha de aprobación trámite ... */
DROP TABLE IF EXISTS #tmp_re_2
SELECT * INTO #tmp_re_2
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY sccm.uIdPersona ORDER BY sccm.dFechaAprobacion DESC)nFila FROM #tmp_re_1 sccm) tmp
WHERE tmp.nFila = 1

-- Index `tmp`
CREATE NONCLUSTERED INDEX ix_tmp_re_2_uIdpersona
ON #tmp_re_2(uIdpersona)

/*» PASO-03 ...*/
--DROP TABLE #tmp_RE_3
--SELECT TOP 10 * FROM #tmp_CCM_3 
SELECT * INTO #tmp_RE_3
FROM(
	SELECT 
		sccm.*,
		smm.sTipo Tipo_Control,
		smm.dFechaControl Fecha_Control,
		smm.sIdPaisMov Pais_Movimiento,
		scm.nIdCalidad Id_Calidad_Movimiento,
		scm.sDescripcion Calidad_Movimiento,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)nFilaMovMig
	FROM #tmp_RE_2 sccm
	JOIN SimMovMigra smm ON sccm.uIdPersona = smm.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
) tmp
WHERE tmp.nFilaMovMig = 1

/*» PASO-04 ... */
--SELECT * FROM #tmp_pv_re
--DROP TABLE #tmp_pv_re
SELECT * INTO #tmp_pv_re FROM (
	SELECT
		sccm.*,
		st.sNumeroTramite,
		st.dFechaHoraReg,
		st.nIdTipoTramite,
		ROW_NUMBER() OVER (PARTITION BY sccm.uIdPersona ORDER BY st.dFechaHoraReg DESC) nFila_pv
	FROM #tmp_RE_3 sccm
	JOIN SimTramite st ON sccm.uIdPersona = st.uIdPersona
	WHERE
		st.nIdTipoTramite = 39 --Permiso de Viaje
		AND st.dFechaHoraReg <= sccm.Fecha_Control
) tmp
WHERE tmp.nFila_pv = 1

/*» PASO-05: Resultado ...*/
--DROP TABLE #tmp_re_result
--SELECT TOP 1 * FROM tmp_re_result
SELECT 
	sccm.*,
	pv.sNumeroTramite,
	pv.dFechaHoraReg,
	pv.nIdTipoTramite
	INTO tmp_re_result
FROM #tmp_RE_3 sccm
LEFT JOIN #tmp_pv_re pv ON sccm.uIdPersona = pv.uIdPersona
/*» ============================================================================================================================================================================================= */


/*» ============================================================ MOVIMIENTOS MIGRATORIOS ========================================================== */
/*» PASO-01: Exponer el ultimo movimieno migratorio del ciudadano extranjero ... */
DROP TABLE IF EXISTS #tmp_mm_1
SELECT 
	*
	INTO #tmp_mm_1 
FROM (
	SELECT
		sp.uIdPersona,
		(smm.sIdMovMigratorio)Id_Mov_Migra,
		[Fecha_Control] = smm.dFechaControl,
		[Tipo_MovMig] = smm.sTipo,
		[Fecha_Aprobacion] = smm.dFechaControl, -- SimMovMigra[Fecha_Control] y SimTramite[Fecha_Aprob]. La fecha mas reciente determina la calidad migratoria ...
		[Fecha_Vencimiento] = '',
		[Tipo_Tramite] = '',
		(scm.sDescripcion) Calidad_Migratoria_Viaje,
		Tipo_Calidad = CASE (scm.sTipo)
							WHEN 'R' THEN 'RESIDENTE'
							WHEN 'T' THEN 'TEMPORAL'
							ELSE '-'
						END,
		-- (sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno)Beneficiario,
		[Beneficiario] = smm.sNombres,
		(sp.sSexo) Sexo,
		(sp.dFechaNacimiento)Fecha_Nacimiento,
		(sp.sIdPaisNacionalidad)Pais_Nacionalidad,
		(sp.sIdPaisNacimiento)Pais_Nacimiento,
		(sp.sIdPaisResidencia)Pais_Residencia,
		(spr.sDescripcion) Profesion,
		[Ubigeo_Domicilio] = se.sIdUbigeoDomicilio,
		[Domicilio] = se.sDomicilio,
		[nRow_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
	JOIN SimPais spa ON smm.sIdPaisNacionalidad = spa.sIdPais
	LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
	LEFT JOIN SimProfesion spr ON sp.sIdProfesion = spr.sIdProfesion
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
		AND sp.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
) mm
WHERE
	mm.nRow_mm = 1
	AND mm.Tipo_MovMig = 'E'
/*» ============================================================================================================================================================================================= */

-- =============================================================================================================================================================================================
--- ◄► FINAL: RESIDENTES ...
-- =============================================================================================================================================================================================
-- STEP-01: Unir las tablas de trámites: CCM, PRR y REG ...
DROP TABLE IF EXISTS #tmp_union_tramites
SELECT tmp.* INTO #tmp_union_tramites FROM (
	SELECT * FROM #tmp_ccm_2
	UNION ALL
	SELECT * FROM #tmp_prr_2
	UNION ALL 
	SELECT * FROM #tmp_re_2
) tmp

CREATE NONCLUSTERED INDEX ux_tmp_union_tramites_uIdPersona
    ON #tmp_union_tramites(uIdPersona, Fecha_Aprobacion)

-- STEP-02: Exponer el ultimo trámite de la persona ...
DROP TABLE IF EXISTS #tmp_union_tramites_final
SELECT tmp.* INTO #tmp_union_tramites_final
FROM (
	SELECT 
		t.*,
		[nRow_r] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY t.Fecha_Aprobacion DESC)
	FROM #tmp_union_tramites t
) tmp
WHERE tmp.nRow_r = 1

-- Index: Optional ...
CREATE NONCLUSTERED INDEX ux_tmp_union_tramites_final_uIdPersona
    ON #tmp_union_tramites_final(uIdPersona)

-- STEP_03: Adicionar campo a `tmp` → tramites_final, ciudadanos dentro del Pais ...
DROP TABLE IF EXISTS #tmp_tramites_final_dentropais
SELECT 
	mm.*,
	[¿Dentro del pais?] = CASE 
								WHEN mm.sTipo IS NULL THEN 'Sin Historial Migratorio'
								WHEN mm.sTipo = 'E' THEN 'Si'
								ELSE 'NO'
						  END
	INTO #tmp_tramites_final_dentropais 
FROM (
		SELECT 
			t.*,
			smm.sTipo,
			[nDentro_mm] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY smm.dFechaControl DESC)
		FROM #tmp_union_tramites_final t
		LEFT OUTER JOIN SimMovMigra smm ON t.uIdPersona = smm.uIdPersona
) AS mm
WHERE mm.nDentro_mm = 1

SELECT TOP 1 * FROM #tmp_tramites_final_dentropais
SELECT TOP 1 * FROM #tmp_mm_1

-- STEP-04: Unir `Trámites` y `MovMig` ...
DROP TABLE IF EXISTS #tmp_union_tramites_y_mm
SELECT * INTO #tmp_union_tramites_y_mm FROM (
	SELECT [Fuente] = 'SimTramite', * FROM #tmp_tramites_final_dentropais
	UNION ALL
	SELECT 
		[Fuente] = 'SimMovMigra', 
		*, 
		[nAux] = '', 
		[sTipo_mm] = '',
		[nDentro_mm] = '',
		[¿Dentro del pais?] = 'Si' 
	FROM #tmp_mm_1
) mm

-- Index `tmp`
CREATE NONCLUSTERED INDEX ux_tmp_union_tramites_y_mm_uIdPersona
    ON #tmp_union_tramites_y_mm(uIdPersona)

-- ◄► STEP-05-FINAL: Expone el ultimo evento[Trámite | MovMig] realizado por el ciudadano ...
DROP TABLE IF EXISTS tmp_ulti_evento
SELECT tmp.* INTO tmp_ulti_evento FROM (
	SELECT 
		tm.*,
		[nRow_f] = ROW_NUMBER() OVER (PARTITION BY tm.uIdPersona ORDER BY tm.Fecha_Aprobacion DESC)
	FROM #tmp_union_tramites_y_mm tm
) tmp
WHERE tmp.nRow_f = 1

-- Index `tmp`
CREATE NONCLUSTERED INDEX ix_tmp_ulti_evento_uIdPersona
    ON tmp_ulti_evento(uIdPersona, Calidad_Migratoria)

-- Delete: Calidad → `Peruano` de tmp → `tmp_ulti_evento`
BEGIN TRAN
-- COMMIT TRAN
DELETE FROM tmp_ulti_evento
WHERE Calidad_Migratoria LIKE '%perua%'
ROLLBACK TRAN

/*
	→ Remove: CalMigra → Peruano
	SELECT * FROM SimCalidadMigratoria WHERE sDescripcion LIKE
*/

-- Data-Set:
DROP TABLE IF EXISTS SimResidentes
SELECT 
	tm.uIdPersona,
	tm.Fuente,
	tm.Numero_Tramite,
	[Fecha_Tramite/Fecha_Control] = tm.Fecha_Tramite,
	[Estado/Tipo_Control] = tm.Estado_Tramite,
	[Fecha_Aprobacion/Fecha_Control] = tm.Fecha_Aprobacion,
	tm.Fecha_Vencimiento,
	tm.Tipo_Tramite,
	tm.Calidad_Migratoria,
	tm.Tipo_Calidad,
	[Ciudadano] = tm.Beneficiario,
	tm.Sexo,
	tm.Fecha_Nacimiento,
	tm.Pais_Nacimiento,
	tm.Pais_Nacionalidad,
	tm.Pais_Residencia,
	tm.Profesion,
	[Ubigeo_Domicilio] = tm.sIdUbigeoDomicilio,
	[Domicilio] = tm.sDomicilio,
	tm.[¿Dentro del pais?]
	INTO SimResidentes
FROM tmp_ulti_evento tm

SELECT * FROM SimTramitePas

SELECT TOP 1 * FROM SimResidentes

-- Output ...
SELECT TOP 10 * FROM tmp_ulti_evento tm


-- Test: ... SELECT * FROM #calmig_sin_informacion
SELECT 
	*,
	[nRow] = ROW_NUMBER() OVER (PARTITION BY tmp.u)
FROM (
	SELECT 
		mm.*,
		st.sNumeroTramite,
		st.dFechaHoraReg [dFechaTramite],
		sti.dFechaFin,
		scm.sDescripcion [Calidad_Migra_Tramite]
	FROM #calmig_sin_informacion mm
	LEFT JOIN SimTramite st ON mm.uIdPersona = st.uIdPersona
	LEFT JOIN SimTramiteInm sti ON sti.sNumeroTramite = st.sNumeroTramite
	LEFT JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	LEFT JOIN SimCalidadMigratoria scm ON scm.nIdCalidad = sccm.nIdCalSolicitada
	WHERE
		st.nIdTipoTramite = 58 -- CCM
		AND sti.sEstadoActual IN ('A', 'P')
		AND sti.nIdEtapaActual IN ( -- Etapas posteriores a la pre-eval ...
			SELECT 
				se.nIdEtapa
			FROM SimEtapaTipoTramite sett
			JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
			WHERE 
				sett.nIdTipoTramite = 58 -- CCM
				AND sett.nSecuencia >= 4
		)
) tmp
ORDER BY 
	st.uIdPersona, st.dFechaHoraAud DESC



-- Test: Inconsistencia en reporte: Residentes ...
SELECT * FROM SimMovMigra smm WHERE smm.sIdMovMigratorio = '2018AI04627528'
SELECT * FROM SimPersona sp WHERE sp.uIdPersona = '8D09C673-9620-4637-9BE3-DF6AE8103F9B'

SELECT * FROM SimMovMigra smm 
WHERE smm.uIdPersona = '8D09C673-9620-4637-9BE3-DF6AE8103F9B'
ORDER BY
	smm.dFechaControl DESC
SELECT * FROM SimCalidadMIgratoria sc WHERE sc.sDescripcion LIKE '%Sin info%'

-- ◄► Paginación ...
DECLARE @recordsByPage INT = 300000,
	    @currentPage INT = 1

DROP TABLE IF EXISTS #residentes_final
SELECT 
	-- COUNT(1)
	tmp.* 
	-- INTO #residentes_final 
FROM (
	SELECT 
		r.*,
		[nRow_f] = ROW_NUMBER() OVER (PARTITION BY r.uIdPersona ORDER BY r.Fecha_Aprobacion DESC)
	FROM #residentes_union r
) tmp
WHERE 
	tmp.nRow_f = 1
	AND tmp.Fuente = 'SimMovMigra'
ORDER BY tmp.uIdPersona
OFFSET (@recordsByPage * (@currentPage - 1)) ROWS
FETCH NEXT @recordsByPage ROWS ONLY
-- ===================================================================================================================

/*► Residentes por profesión ... */
SELECT 
	r.Profesion,
	[Total_Residentes] = COUNT(1)
FROM #residentes_final r
GROUP BY r.Profesion
ORDER BY [Total_Residentes] DESC


/*► Residentes por profesión ... */
SELECT 
	sp.sNacionalidad,
	[Total_Residentes] = COUNT(1)
FROM #residentes_final r
JOIN SimPais sp ON r.Pais_Nacionalidad = sp.sIdPais
GROUP BY sp.sNacionalidad
ORDER BY [Total_Residentes] DESC

/*» ============================================================================================================================================================================================= */





















/*» ============================================================ CCM ========================================================== */
/*» PASO-01 ...*/
--SELECT se.sDescripcion, * FROM SimEtapaTipoTramite sett JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa WHERE sett.nIdTipoTramite = 58 ORDER BY sett.nSecuencia
/*→ Calidad: 318 | HUM */
--DROP TABLE #tmp_HUM_1
--SELECT TOP 10 * FROM [dbo].[SimPersonaHumMRE] sph ORDER BY sph.FechaRegistro ASC
--SELECT * FROM #tmp_HUM_1

SELECT
	sp.uIdPersona, 
	st.sNumeroTramite Numero_Tramite, 
	st.dFechaHoraReg Fecha_Tramite, 
	Estado_Tramite = 'A', 
	sph.dFechaOficio Fecha_Aprobacion, 
	sph.dFechaVencRes Fecha_Vencimiento, 
	stt.sDescripcion Tipo_Tramite,
	(scm.sDescripcion)Calidad_Migratoria,
	Tipo_Calidad = CASE (scm.sTipo)
						WHEN 'R' THEN 'RESIDENTE'
						WHEN 'T' THEN 'TURISTA'
						ELSE 'RESIDENTE'
					END,
	(sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno)Beneficiario,
	(sp.sSexo)Sexo,
	(sp.dFechaNacimiento)Fecha_Nacimiento,
	(sp.sIdPaisNacionalidad)Pais_Nacionalidad,
	(sp.sIdPaisNacimiento)Pais_Nacimiento,
	(sp.sIdPaisResidencia)Pais_Residencia,
	(spr.sDescripcion)Profesion,
	se.sIdUbigeoDomicilio,
	se.sDomicilio
	INTO #tmp_HUM_1
FROM SimPersonaHumMRE sph
JOIN SimPersona sp ON sph.uidPersona = sp.uIdPersona
JOIN SimCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
LEFT JOIN SimTramite st ON sph.uidPersona = st.uIdPersona
LEFT JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
LEFT JOIN SimProfesion spr ON sp.sIdProfesion = spr.sIdProfesion
WHERE
	st.nIdTipoTramite = 62


/*» PASO-02: Ordena registros por persona de manera descendente por fecha de aprobación trámite ... */
--DROP TABLE #tmp_CCM_2
/*SELECT * INTO #tmp_CCM_2
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY sccm.uIdPersona ORDER BY sccm.Fecha_Aprobacion DESC)nFila FROM #tmp_CCM_1 sccm) tmp
WHERE tmp.nFila = 1*/

/*» PASO-03 ...*/
--DROP TABLE #tmp_HUM_2
--SELECT TOP 10 * FROM #tmp_CCM_3 
SELECT * INTO #tmp_HUM_2
FROM(
	SELECT 
		hum.*,
		smm.sTipo Tipo_Control,
		smm.dFechaControl Fecha_Control,
		smm.sIdPaisMov Pais_Movimiento,
		scm.nIdCalidad Id_Calidad_Movimiento,
		scm.sDescripcion Calidad_Movimiento,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)nFilaMovMig
	FROM #tmp_HUM_1 hum
	JOIN SimMovMigra smm ON hum.uIdPersona = smm.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
) tmp
WHERE tmp.nFilaMovMig = 1

/*» PASO-04 ... */
--SELECT * FROM #tmp_pv
--DROP TABLE #tmp_pv
SELECT * INTO #tmp_pv FROM (
	SELECT
		hum.*,
		st.sNumeroTramite,
		st.dFechaHoraReg,
		st.nIdTipoTramite,
		ROW_NUMBER() OVER (PARTITION BY hum.uIdPersona ORDER BY st.dFechaHoraReg DESC) nFila_pv
	FROM #tmp_HUM_2 hum
	JOIN SimTramite st ON hum.uIdPersona = st.uIdPersona
	WHERE
		st.nIdTipoTramite = 39 --Permiso de Viaje
		AND st.dFechaHoraReg <= hum.Fecha_Control
) tmp
WHERE tmp.nFila_pv = 1

/*» PASO-05: Resultado ...*/
--DROP TABLE tmp_hum_result
--SELECT TOP 10 * FROM #tmp_ccm_result
SELECT 
	hum.*,
	pv.sNumeroTramite,
	pv.dFechaHoraReg,
	pv.nIdTipoTramite
	INTO tmp_hum_result
FROM #tmp_HUM_2 hum
LEFT JOIN #tmp_pv pv ON hum.uIdPersona = pv.uIdPersona
/*» ============================================================================================================================================================================================= */


/*» REGULARIZACIÓN DE EXTRANJEROS */
/*-----------------------------------------------------------------------------------------------------*/
SELECT 
	st.nIdTipoTramite,
	stt.sDescripcion Tipo_Tramite,
	sti.sEstadoActual,
	sccm.*
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimCambioCalMig sccm ON sti.sNumeroTramite = sccm.sNumeroTramite
WHERE 
	st.nIdTipoTramite = 113
	AND sti.sEstadoActual = 'A'
	AND sti.dFechaHoraAud >= '2021-01-01 00:00:00'
/*-----------------------------------------------------------------------------------------------------*/



