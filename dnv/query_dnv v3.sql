USE SIM
GO

-- STEP-01: ...
SELECT 
	-- spna.*,
	-- sdi.*,
	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	spna.sNumDocIdentidad,
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	spna.dFechaInicioMedida,
	sdi.dFechaEmision,
	sdi.dFechaRecepcion,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = stt.sDescripcion,
	sdi.sObservaciones,
	[sOperador] = su.sNombre,
	[sIdModulo] = sm.sIdModulo,
	[sModulo] = sm.sDescripcion,
	[sDependencia] = sd.sNombre,
	[sArea] = so.sDescripcion,
	spna.bActivo
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
	AND stt.sDescripcion IS NOT NULL
ORDER BY
	sdi.dFechaEmision




-- Test ...
SELECT sdi.* FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
WHERE
	spna.sNombre = 'PAULO SERGIO'
	AND spna.sPaterno = 'LOZANO'
	AND spna.sMaterno = 'VALERA'

SELECT TOP 10 * FROM SimPersonaNoAutorizada



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
	spna.bActivo = 0
	-- AND stt.sDescripcion IS NOT NULL


-- index
CREATE CLUSTERED INDEX IX_tmp_s1_dnv_with_uid
    ON #tmp_s1_dnv_with_uid([uId])

-- Test ...
SELECT * FROM #tmp_s1_dnv_with_uid
SELECT * FROM SimMotivoInvalidacion
SELECT TOP 100 * FROM SimPersonaNoAutorizada ORDER BY dFechaHoraAud DESC
SELECT TOP 100 * FROM [dbo].[SimMotivo]
SELECT TOP 100 * FROM [dbo].[SimMotivoInvDoc]
SELECT TOP 100 * FROM [dbo].[SimTipoMotivo]
SELECT TOP 100 * FROM [dbo].[SimMotivoTramite]
SELECT TOP 100 * FROM SimModulo sm WHERE sm.sDescripcion LIKE '%sis%'

SELECT TOP 100 * FROM [dbo].[SimAlertaPersonaReferida]
SELECT TOP 100 * FROM SimPRAudit spra
WHERE
	spra.sNombre LIKE '%LUIS%'
	AND spra.sPaterno = 'PACHECO'
	AND spra.sMaterno = 'VIERMA'

SELECT TOP 100 * FROM [dbo].[SimProcesoAlerta]
SELECT TOP 100 * FROM [dbo].[SimConfiguradorAlertaMMFFAA]
SELECT TOP 100 * FROM [dbo].[SimCmmAlerta]
SELECT TOP 100 * FROM [dbo].[SimAuditoriaAlertasEgate]
SELECT TOP 100 * FROM [dbo].[SimAuditoriaAlertaMovMigratorio]

SELECT TOP 100 * FROM [dbo].[SimInmAlertaTramite]
SELECT TOP 100 * FROM [dbo].[SimAlertaPersonaReferida]

SELECT 
	siat.* 
FROM SimInmAlertaTramite siat
JOIN SimTramite st ON siat.sNumeroTramite = st.sNumeroTramite
JOIN SimPersona sp On st.uIdPersona = sp.uIdPersona
WHERE
	sp.sNombre LIKE '%LUIS JAVIER%'
	AND sp.sPaterno = 'PACHECO'
	AND sp.sMaterno = 'VIERMA'

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

SELECT TOP 100 * FROM [dbo].[SimRestriccionServicioInst]
SELECT TOP 100 * FROM [dbo].[SimTipoRestriccionImagenWeb]
SELECT TOP 100 * FROM [dbo].[SimPersonaRestringidoCMM]
SELECT TOP 100 * FROM [dbo].[SimDepuracionDniActivoDocPersona] ddni
WHERE ddni.sObservaciones IS NOT NULL

SELECT * FROM SimPersona sp
WHERE 
	-- sp.uIdPersona = 'C13077A5-D259-440D-886F-986AD789648C'
	sp.sNumDocIdentidad = '46392613'
	/*sp.sNombre = 'CARLOS ALFREDO'
	AND sp.sPaterno = 'AVILES'
	AND sp.sMaterno = 'ABREGU'*/

SELECT * FROM SimMovMigra smm
WHERE
	smm.uIdPersona = 'A497F360-A601-4695-8A76-7B65BB661C3C'



SELECT * FROM BD_SIRIM.dbo.RimPasaporte p
WHERE
	p.sNombre = 'Manuel Augusto'
	AND p.sApePat = 'Montes'
	AND p.sApeMat = 'Boza'

SELECT * FROM BD_SIRIM.dbo.RimPasaporte p
WHERE
	p.sNombre = 'Manuel Augusto'
	AND p.sApePat = 'Montes'
	AND p.sApeMat = 'Boza'	


SELECT * FROM 