USE SIM
GO

/*░
	-- bActivo
	-- 0 → Habilitada
	-- 1 → Inhabilitada
===========================================*/

-- STEP-01: ...
-- 1.1: `tmp` Identidades únicas de ciudadanos extranjeros ...
-- 1.1.1: SimPersona 
DROP TABLE IF EXISTS #tmp_SimPersona
SELECT 
	sper.uIdPersona,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sNumDocIdentidad,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad,
	sper.nIdCalidad,
	[nTotalTramites] = (
							(SELECT COUNT(1) FROM SimTramite st 
							 WHERE st.uIdPersona = sper.uIdPersona)
							 +
							(SELECT COUNT(1) FROM SimMovMigra smm 
							 WHERE smm.uIdPersona = sper.uIdPersona)
						)
	INTO #tmp_SimPersona
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_SimPersona_sNombre_sPaterno_sMaterno_dFechaNacimiento_sIdPaisNacionalidad
    ON dbo.#tmp_SimPersona(sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad)

-- 1.1.2
DROP TABLE IF EXISTS #tmp_SimPersona_distinct
SELECT * INTO #tmp_SimPersona_distinct FROM (

	SELECT 
		sper.uIdPersona,
		sper.sNombre,
		sper.sPaterno,
		sper.sMaterno,
		sper.sNumDocIdentidad,
		sper.dFechaNacimiento,
		sper.sIdPaisNacionalidad,
		[sCalidadMigratoria] = scm.sDescripcion,
		[nFila] = ROW_NUMBER() OVER (PARTITION BY sper.sNombre, sper.sPaterno, sper.sMaterno, sper.dFechaNacimiento, sper.sIdPaisNacionalidad ORDER BY sper.nTotalTramites DESC)
	
	FROM #tmp_SimPersona sper 
	JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad

) tmp
WHERE tmp.nFila = 1

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_SimPersona_distinct_sNombre_sPaterno_sMaterno_sNumDocIdentidad_dFechaNacimiento_sIdPaisNacionalidad
    ON dbo.#tmp_SimPersona_distinct(sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad)
	
-- 1.2: Filtros para encontar uIdPersona.
-- 1.2.1: Primer filtro por sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad
-- DNV = 80,259
-- SELECT COUNT(1) FROM #tmp_dnv = 80,259
-- 81,273
SELECT COUNT(1) FROM SimPersonaNoAutorizada spna
WHERE
	spna.bActivo = 1

DROP TABLE IF EXISTS #tmp_dnv
SELECT 
	sper.uIdPersona,
	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	[sNumDocIdentidad] = CONCAT('''', spna.sNumDocIdentidad),
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	sper.sCalidadMigratoria,
	spna.dFechaInicioMedida,
	sdi.dFechaEmision,
	sdi.dFechaRecepcion,
	[dFechaCancelacion_DNV] = spna.dFechaCancelacion,
	[dFechaHoraAud_DNV] = spna.dFechaHoraAud,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
	[sObservaciones1] = sdi.sObservaciones,
	[sObservaciones2] = spna.sObservaciones,
	[sOperador] = su.sNombre,
	[sIdModulo] = sm.sIdModulo,
	[sModulo] = sm.sDescripcion,
	[sDependencia] = sd.sNombre,
	[sArea] = so.sDescripcion,
	spna.bActivo
	INTO #tmp_dnv
FROM SimPersonaNoAutorizada spna
LEFT JOIN #tmp_SimPersona_distinct sper ON spna.sNombre = sper.sNombre 
									    AND spna.sPaterno = sper.sPaterno 
									    AND spna.sMaterno = sper.sMaterno 
									    AND spna.dFechaNacimiento = sper.dFechaNacimiento
									    AND spna.sIdPaisNacionalidad = sper.sIdPaisNacionalidad
LEFT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimSesion ss ON sdi.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
LEFT JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
LEFT JOIN SimOrganigrama so ON su.sCodigoArea = so.sCodigoArea
LEFT JOIN SimDependencia sd ON su.sIdDependencia = sd.sIdDependencia
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
	spna.bActivo = 1
	-- AND spna.sObservaciones LIKE '%CARPITAS%' OR sdi.sObservaciones LIKE '%CARPITAS%'


-- 1.2.2: Primer filtro para uIdPersona por sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad
-- 1.2.3: Union filtros ...


-- Test ...
SELECT COUNT(1) FROM #tmp_dnv dnv WHERE dnv.uIdPersona IS NULL

-- 1.2: uId's no nulos ...
DROP TABLE IF EXISTS #tmp_uId_distinct
SELECT DISTINCT dnv.uIdPersona INTO #tmp_uId_distinct
FROM #tmp_dnv dnv
WHERE dnv.uIdPersona IS NOT NULL

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_uId_distinct_uIdPersona
    ON dbo.#tmp_uId_distinct(uIdPersona)

-- 1.3: Trámites `A` de CCM, CPP, PTP-RS109 ...
DROP TABLE IF EXISTS #tmp_uId_distinct_traminm
SELECT * INTO #tmp_uId_distinct_traminm FROM (

	SELECT 
		t_inm1.*,
		[nFilaInm] = ROW_NUMBER() OVER (PARTITION BY t_inm1.uIdPersona ORDER BY t_inm1.dFechaAprobacion DESC)

	FROM (

		SELECT 
			st.uIdPersona,
			st.sNumeroTramite,
			[sTipoTramite] = stt.sDescripcion,
			sti.sEstadoActual,
			[dFechaAprobacion] = (
			
				CASE 
					WHEN st.nIdTipoTramite = 58 THEN ( -- CCM
				
						COALESCE(
							sccm.dFechaAprobacion,
							(
								SELECT TOP 1 seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
								WHERE 
									seti.sNumeroTramite = st.sNumeroTramite
									AND seti.nIdEtapa = 23 -- 23 | CONFORMIDAD DIREC.INMGRACION.
									AND seti.bActivo = 1
									AND seti.sEstado = 'F'
								ORDER BY
									seti.dFechaHoraFin DESC
							),
							'1900-01-01 00:00:00.000'
						)
				
					)
					WHEN st.nIdTipoTramite = 113 OR st.nIdTipoTramite = 126 THEN ( -- CPP

						SELECT TOP 1 seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
						WHERE 
							seti.sNumeroTramite = st.sNumeroTramite
							AND seti.nIdEtapa = 75 -- 75 | CONFORMIDAD JEFATURA ZONAL
							AND seti.bActivo = 1
							AND seti.sEstado = 'F'
						ORDER BY
							seti.dFechaHoraFin DESC

					)

				END
		
			)
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
		JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
		WHERE
			st.bCancelado = 0
			AND sti.sEstadoActual = 'A'
			AND st.nIdTipoTramite IN (58, 113, 126)
			AND EXISTS (
					SELECT 1 FROM #tmp_uId_distinct uIdDnv WHERE uIdDnv.uIdPersona = st.uIdPersona
			)

	) t_inm1

)  t_inm2 
WHERE
	t_inm2.nFilaInm = 1


-- 1.4: Trámites todos estados de PRR ...
DROP TABLE IF EXISTS #tmp_uId_distinct_traminm_prr
SELECT * INTO #tmp_uId_distinct_traminm_prr FROM (

	SELECT 
		t_inm1.*,
		[nFilaInm] = ROW_NUMBER() OVER (PARTITION BY t_inm1.uIdPersona ORDER BY t_inm1.dFechaTramite DESC)

	FROM (

		SELECT 
			st.uIdPersona,
			st.sNumeroTramite,
			[sTipoTramite] = stt.sDescripcion,
			sti.sEstadoActual,
			[dFechaTramite] = st.dFechaHoraReg,
			[dFechaAprobacion] = (

						SELECT TOP 1 seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
						WHERE 
							seti.sNumeroTramite = st.sNumeroTramite
							AND seti.nIdEtapa = 22 -- 22 | CONFORMIDAD SUB-DIREC.INMGRA.
							AND seti.bActivo = 1
							AND seti.sEstado = 'F'
						ORDER BY
							seti.dFechaHoraFin DESC

					)
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
		-- JOIN SimProrroga sprr ON st.sNumeroTramite = sprr.sNumeroTramite
		WHERE
			st.bCancelado = 0
			-- AND sti.sEstadoActual IN ('A', 'P')
			AND st.nIdTipoTramite IN (57) -- PRR
			AND EXISTS (
					SELECT 1 FROM #tmp_uId_distinct uIdDnv WHERE uIdDnv.uIdPersona = st.uIdPersona
			)

	) t_inm1

)  t_inm2 
WHERE
	t_inm2.nFilaInm = 1

-- 1.4: Trámites `PENDIENTES` de CCM, CPP y PTP-RS109 ...
DROP TABLE IF EXISTS #tmp_uId_distinct_traminm_P
SELECT * INTO #tmp_uId_distinct_traminm_P FROM (

	SELECT 
		t_inm1.*,
		[nFilaInm] = ROW_NUMBER() OVER (PARTITION BY t_inm1.uIdPersona ORDER BY t_inm1.dFechaTramite DESC)

	FROM (

		SELECT 
			st.uIdPersona,
			st.sNumeroTramite,
			[sTipoTramite] = stt.sDescripcion,
			sti.sEstadoActual,
			[dFechaTramite] = st.dFechaHoraReg
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
		JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
		WHERE
			st.bCancelado = 0
			AND sti.sEstadoActual = 'P'
			AND st.nIdTipoTramite IN (58, 113, 126)
			AND EXISTS (
					SELECT 1 FROM #tmp_uId_distinct uIdDnv WHERE uIdDnv.uIdPersona = st.uIdPersona
			)

	) t_inm1

)  t_inm2 
WHERE
	t_inm2.nFilaInm = 1

-- 1.4: 
-- 1.4.1: Extrae ultimo movimiento migratorio: Activos ...
DROP TABLE IF EXISTS #tmp_dnv_ultmovmigra
SELECT * INTO #tmp_dnv_ultmovmigra FROM (

	SELECT
		smm.uIdPersona,
		[sUltimoMovMigra] = smm.sTipo,
		[dFechaUltimoMovMigra] = smm.dFechaControl,
		[sObservaciones_MovMigra] = smm.sObservaciones,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN #tmp_dnv dnv ON smm.uIdPersona = dnv.uIdPersona
	WHERE
		smm.bAnulado = 0
		AND smm.bTemporal = 0

) smm2
WHERE
	smm2.nFila_mm = 1

-- 1.4.2: Extrae ultimo movimiento migratorio: Anulados ...
DROP TABLE IF EXISTS #tmp_dnv_ultmovmigra_a
SELECT * INTO #tmp_dnv_ultmovmigra_a FROM (

	SELECT
		smm.uIdPersona,
		[sUltimoMovMigra] = smm.sTipo,
		[dFechaUltimoMovMigra] = smm.dFechaControl,
		[sObservaciones_MovMigra] = smm.sObservaciones,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN #tmp_dnv dnv ON smm.uIdPersona = dnv.uIdPersona
	WHERE
		smm.bAnulado = 1
		AND smm.bTemporal = 0

) smm2
WHERE
	smm2.nFila_mm = 1

-- Index ...
CREATE INDEX IX_tmp_dnv_ultmovmigra_uIdPersona
    ON dbo.#tmp_dnv_ultmovmigra(uIdPersona)

CREATE INDEX IX_tmp_dnv_ultmovmigra_a_uIdPersona
    ON dbo.#tmp_dnv_ultmovmigra_a(uIdPersona)

-- 5. Final: ...
-- 5.1: tmp Aux ...
DROP TABLE IF EXISTS #tmp_contar_sNumDocIdentidad_dnv
SELECT 
	[sNumDocIdentidad] = dnv.sNumDocIdentidad,
	[nContar] = COUNT(1)
	INTO #tmp_contar_sNumDocIdentidad_dnv
FROM #tmp_dnv dnv
GROUP BY
	dnv.sNumDocIdentidad

-- 5.2: tmp Aux datos ...
DROP TABLE IF EXISTS #tmp_contar_sDatos_dnv
SELECT 
	[sNombre]= LTRIM(RTRIM(dnv.sNombre)),
	[sPaterno] = LTRIM(RTRIM(dnv.sPaterno)),
	[sMaterno] = LTRIM(RTRIM(dnv.sMaterno)),
	-- dnv.sSexo,
	-- dnv.dFechaNacimiento,
	dnv.sIdPaisNacionalidad,
	[nContarDatos] = COUNT(1)
	INTO #tmp_contar_sDatos_dnv
FROM #tmp_dnv dnv
GROUP BY
	LTRIM(RTRIM(dnv.sNombre)),
	LTRIM(RTRIM(dnv.sPaterno)),
	LTRIM(RTRIM(dnv.sMaterno)),
	-- dnv.sSexo,
	-- dnv.dFechaNacimiento,
	dnv.sIdPaisNacionalidad
ORDER BY
	[nContarDatos] DESC

-- 5.3: Final ...
SELECT 
	dnv.*,
	inm.sNumeroTramite,
	inm.sTipoTramite,
	inm.sEstadoActual,
	inm.dFechaAprobacion,

	[nContarDuplicadosPorDoc] = dnv_doc.[nContar],
	[nContarDuplicadosPorDatos] = dnv_dat.[nContarDatos],

	[sNumeroTramite(P)] = inm_p.sNumeroTramite,
	[sTipoTramite(P)] = inm_p.sTipoTramite,
	[sEstadoActual(P)] = inm_p.sEstadoActual,
	[dFechaRegistro(P)] = inm_p.dFechaTramite,

	[sNumeroTramite(PRR)] = inm_prr.sNumeroTramite,
	[sTipoTramite(PRR)] = inm_prr.sTipoTramite,
	[sEstadoActual(PRR)] = inm_prr.sEstadoActual,
	[dFechaTramite(PRR)] = inm_prr.dFechaTramite,
	[dFechaAprobación(PRR)] = inm_prr.dFechaAprobacion,

	mm.sUltimoMovMigra,
	mm.dFechaUltimoMovMigra,
	mm.sObservaciones_MovMigra,

	[sUltimoMovMigra(Anulado)] = mma.sUltimoMovMigra,
	[dFechaUltimoMovMigra(Anulado)] = mma.dFechaUltimoMovMigra,
	[sObservaciones_MovMigra(Anulado)] = mma.sObservaciones_MovMigra
FROM #tmp_dnv dnv
LEFT JOIN #tmp_uId_distinct_traminm inm ON dnv.uIdPersona = inm.uIdPersona
LEFT JOIN #tmp_uId_distinct_traminm_P inm_p ON dnv.uIdPersona = inm_p.uIdPersona
LEFT JOIN #tmp_uId_distinct_traminm_prr inm_prr ON dnv.uIdPersona = inm_prr.uIdPersona
LEFT JOIN #tmp_dnv_ultmovmigra mm ON dnv.uIdPersona = mm.uIdPersona
LEFT JOIN #tmp_dnv_ultmovmigra_a mma ON dnv.uIdPersona = mma.uIdPersona
LEFT JOIN #tmp_contar_sNumDocIdentidad_dnv dnv_doc ON dnv.sNumDocIdentidad = dnv_doc.sNumDocIdentidad
LEFT JOIN #tmp_contar_sDatos_dnv dnv_dat ON dnv.sNombre = dnv_dat.sNombre
										 AND dnv.sPaterno = dnv_dat.sPaterno
										 AND dnv.sMaterno = dnv_dat.sMaterno
										 AND dnv.sIdPaisNacionalidad = dnv_dat.sIdPaisNacionalidad



/*»
	→ ...
====================================================================================================================================================*/

-- STEP-01: Crear identificador único del ciudadano ...
DROP TABLE IF EXISTS #tmp_s1_dnv_with_uid
SELECT 
	[uId] = CONCAT(
				REPLACE(ISNULL(spna.sNombre, ''), ' ', ''), 
				REPLACE(ISNULL(spna.sPaterno, ''), ' ', ''), 
				REPLACE(ISNULL(spna.sMaterno, ''), ' ', ''),
				REPLACE(ISNULL(spna.sSexo, ''), ' ', ''),
				CONVERT(CHAR(8), spna.dFechaNacimiento, 112), spna.sIdPaisNacionalidad
			),
	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', REPLACE(sdi.sNumDocInvalida, ' ', '')),
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	spna.sNumDocIdentidad,
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	sdi.dFechaEmision,
	sdi.dFechaRecepcion,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = ISNULL(stt.sDescripcion, 'NO REGISTRA TIPO'),
	sdi.sObservaciones,
	[sOperador] = su.sNombre,
	[sIdModulo] = sm.sIdModulo,
	[sDependencia] = sd.sNombre,

	-- Aux ...
	[sObservaciones_SimInm] = spna.sObservaciones

	INTO #tmp_s1_dnv_with_uid
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
JOIN SimSesion ss ON sdi.nIdSesion = ss.nIdSesion
JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
LEFT JOIN SimOrganigrama so ON su.sCodigoArea = so.sCodigoArea
JOIN  SimDependencia sd ON su.sIdDependencia = sd.sIdDependencia
JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
	spna.bActivo = 1
	-- AND stt.sDescripcion IS NOT NULL


-- index
CREATE CLUSTERED INDEX IX_tmp_s1_dnv_with_uid
    ON #tmp_s1_dnv_with_uid([uId])

-- Test ...
SELECT * FROM #tmp_s1_dnv_with_uid



-- 126 | PERMISO TEMPORAL DE PERMANENCIA - RS109
SELECT 
	TOP 10
	/*sti.sEstadoActual, 
	stt.nIdTipoTramite, 
	stt.sDescripcion, 
	st.*,*/
	sccm.*
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE 
	st.nIdTipoTramite = 126
	AND sti.sEstadoActual = 'A'
	-- st.sNumeroTramite = 'LM230400805'


SELECT TOP 10000 * FROM SimVerificaPDA sv ORDER BY sv.nIdCitaVerifica DESC

SELECT se.nIdEtapa, se.sDescripcion FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE sett.nIdTipoTramite = 57
ORDER BY sett.nSecuencia


SELECT * FROM SimMotivoInvalidacion
SELECT TOP 100 * FROM SimPersonaNoAutorizada ORDER BY dFechaHoraAud DESC
SELECT TOP 100 * FROM [dbo].[SimMotivo]
SELECT TOP 100 * FROM [dbo].[SimMotivoInvDoc]
SELECT TOP 100 * FROM [dbo].[SimTipoMotivo]
SELECT TOP 100 * FROM [dbo].[SimMotivoTramite]
SELECT TOP 100 * FROM SimModulo sm WHERE sm.sDescripcion LIKE '%sis%'
SELECT TOP 100 * FROM [dbo].[SimProcesoAlerta]
SELECT TOP 100 * FROM [dbo].[SimConfiguradorAlertaMMFFAA]
SELECT TOP 100 * FROM [dbo].[SimCmmAlerta]
SELECT TOP 100 * FROM [dbo].[SimAuditoriaAlertasEgate]
SELECT TOP 100 * FROM [dbo].[SimAuditoriaAlertaMovMigratorio]
SELECT TOP 100 * FROM [dbo].[SimInmAlertaTramite]
SELECT TOP 100 * FROM [dbo].[SimAlertaPersonaReferida]


-- STEP-02: Temporal ciudadanos con >1 alerta ...
SELECT * INTO #tmp_s2_dnv_with_mas2_alerta FROM (

	SELECT 
		dnv.*,
		[nTotalAlerta] = COUNT(dnv.[uId]) OVER (PARTITION BY dnv.[uId])
	FROM #tmp_s1_dnv_with_uid dnv

) dnv
WHERE
	dnv.nTotalAlerta > 1

-- Test ...
SELECT TOP 100 * FROM #tmp_s2_dnv_with_mas2_alerta

-- STEP-03: Temporal duplicidad de alertas ...
DROP TABLE IF EXISTS #tmp_s3_dnv_with_dupli_alerta
SELECT 
	dnv.*
	INTO #tmp_s3_dnv_with_dupli_alerta 
FROM (

	SELECT 
		dnv.*,
		[nTotalDupliAlerta] = COUNT(1) OVER (PARTITION BY dnv.[uId], dnv.sNumDocInvalida)
	FROM #tmp_s2_dnv_with_mas2_alerta dnv

) dnv
WHERE
	dnv.nTotalDupliAlerta > 1

-- Test ...
SELECT * FROM #tmp_s3_dnv_with_dupli_alerta

-- STEP-04:  ...

CREATE NONCLUSTERED INDEX IX_#tmp_s3_dnv_with_dupli_alerta_uId
    ON #tmp_s3_dnv_with_dupli_alerta(uId)

SELECT 
	* 
FROM #tmp_s3_dnv_with_dupli_alerta dnv_1
WHERE
	EXISTS (
		SELECT 1
		FROM #tmp_s3_dnv_with_dupli_alerta dnv_2
		WHERE
			dnv_2.uId = dnv_1.uId
			AND dnv_2.sTipoAlerta != dnv_1.sTipoAlerta
	)
	

-- ====================================================================================================================================================*/


/*DECLARE @records VARCHAR(MAX),
		@sql NVARCHAR(MAX)

SET @records = '(1, ''Zapatos''), (2, ''Chompas''), (3, ''Pantalones'')'

SET @sql = N'SELECT * FROM (
				VALUES ' + @records + 
			') AS tmp([nId], [sDescripcion])'

EXEC SP_EXECUTESQL @sql*/

-- Exercise ...
SET LANGUAGE SPANISH
DECLARE @records VARCHAR(MAX) = '[2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023], [2024]',
		@sql NVARCHAR(MAX)


SET @sql = 'SELECT * FROM (

	SELECT 
		st.sNumeroTramite,
		[nMesTramite] = DATEPART(MM, st.dFechaHoraReg),
		[sMesTramite] = DATENAME(MONTH, st.dFechaHoraReg),
		[nAñoTramite] = DATEPART(YYYY, st.dFechaHoraReg)
	FROM SimTramite st
	WHERE
		st.dFechaHoraReg >= ''2016-01-01 00:00:00.000''

) st
PIVOT (

	COUNT(st.sNumeroTramite) FOR st.nAñoTramite IN (' + @records + ')' +

') st_pv ORDER BY [nMesTramite]'

EXEC SP_EXECUTESQL @sql


SELECT * FROM SimPersona sp
WHERE
	sp.sNombre = 'JAVIER ANDERSON'
	AND sp.sPaterno = 'LOPEZ'
	AND sp.sMaterno = 'CABALLERO'

SELECT * FROM SimMovMigra smm
WHERE
	smm.uIdPersona = '00854FE9-0928-4215-8E11-7866ED3F3209'


-- Buscar DNV por documento ...
SELECT 
	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	[sNumDocIdentidad] = CONCAT('''', spna.sNumDocIdentidad),
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	spna.dFechaInicioMedida,
	sdi.dFechaEmision,
	sdi.dFechaRecepcion,
	[dFechaCancelacion_DNV] = spna.dFechaCancelacion,
	[dFechaHoraAud_DNV] = spna.dFechaHoraAud,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
	[sObservaciones1] = sdi.sObservaciones,
	[sObservaciones2] = spna.sObservaciones,
	[sOperador] = su.sNombre,
	[sIdModulo] = sm.sIdModulo,
	[sModulo] = sm.sDescripcion,
	[sDependencia] = sd.sNombre,
	[sArea] = so.sDescripcion,
	spna.bActivo
FROM SimPersonaNoAutorizada spna
FULL JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimSesion ss ON sdi.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
LEFT JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
LEFT JOIN SimOrganigrama so ON su.sCodigoArea = so.sCodigoArea
LEFT JOIN SimDependencia sd ON su.sIdDependencia = sd.sIdDependencia
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
	-- sdi.sNumDocInvalida LIKE '%526%2020%DIRNIC%'
	-- sdi.sNumDocInvalida LIKE '%526%DIRNIC%'
	-- sdi.sNumDocInvalida LIKE '%DIRNIC%'
	sdi.sNumDocInvalida LIKE '%526%DIRNIC%'
	OR sdi.sObservaciones LIKE '%526%DIRNIC%'
	OR spna.sObservaciones LIKE '%526%DIRNIC%'

-- Test ...
SELECT TOP 100 * FROM SimPersonaNoAutorizada
SELECT TOP 100 * FROM SimDocInvalidacion

SELECT 
	se.xImagen,
	se.sTipo,
	sper.uIdPersona,
	sper.sPaterno,
	sper.sMaterno,
	sper.sNombre,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacimiento,
	sper.sIdPaisNacionalidad
FROM SimimagenExtranjero se
RIGHT JOIN SimPersona sper ON se.uIdPersona = sper.uIdPersona
WHERE
	-- sper.uIdPersona = ''
	-- se.sTipo = 'F'
	-- AND sper.sIdDocIdentidad = 'PAS'
	-- AND sper.sNumDocIdentidad = 'GV3586875'
	sper.sNumDocIdentidad = 'PP1903683'


SELECT * FROM SimPais sp WHERE sp.sNombre LIKE 'hai%'

SELECT * FROM SimMovMigra smm
WHERE
	-- smm.sNumeroDoc = 'PP2752408'
	smm.sIdPaisNacionalidad = 'HAI'
	AND smm.sNombres LIKE '%skan%'
	OR smm.sNombres LIKE '%gue%'
	