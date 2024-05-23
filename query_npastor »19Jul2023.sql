USE SIM
GO


/* » 
 →
===========================================================================================================*/

CREATE NONCLUSTERED INDEX IX_SimPersona_sNombre_sPaterno_sMaterno_sNumDocIdentidad
    ON dbo.SimPersona(sNombre, sPaterno, sMaterno, sNumDocIdentidad)


-- STEP-1: Crear tmp ...
-- 1
SELECT 
	TOP 0
	[nId] = 0,
	sper.sNumDocIdentidad, 
	sper.sNombre, 
	sper.sPaterno, 
	sper.sMaterno 
	INTO #tmp_per_nac
FROM SimPersona sper

-- Test ...
SELECT * FROM #tmp_per_nac
TRUNCATE TABLE #tmp_per_nac

-- 1.2: Bulk ...
INSERT INTO #tmp_per_nac VALUES(1,'08827233','MARIA BELEN','FARFAN','MARIN')

-- STEP-2: ...
-- 2.1: ...
SELECT nac.nId, sper.uIdPersona INTO #tmp_per_nac_with_uId FROM SimPersona sper
JOIN #tmp_per_nac nac ON 
						sper.sNumDocIdentidad = nac.sNumDocIdentidad
						/*AND sper.sNombre = nac.sNombre
						AND sper.sPaterno = nac.sPaterno
						AND sper.sMaterno = nac.sMaterno*/
ORDER BY nac.nId

-- 2.2: Aux ...
-- 2.2.1: Movimientos Migratorios ...
DROP TABLE IF EXISTS #tmp_nac_mm_aux
SELECT * INTO #tmp_nac_mm_aux FROM (

	SELECT 
		smm.*,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM #tmp_per_nac_with_uId nac
	JOIN SimMovMigra smm ON nac.uIdPersona = smm.uIdPersona

) nac2
WHERE nac2.nFila_mm = 1

-- 2.2.2: tmp_aux → Movimientos Migratorios ...
DROP TABLE IF EXISTS #tmp_nac_mm_aux
SELECT * INTO #tmp_nac_mm_aux FROM (

	SELECT 
		smm.*,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM #tmp_per_nac_with_uId nac
	JOIN SimMovMigra smm ON nac.uIdPersona = smm.uIdPersona

) nac2
WHERE nac2.nFila_mm = 1

-- 2.2.3: tmp_aux → Pasaportes ...
SELECT 
	st.uIdPersona, 
	[nTotalPas] = COUNT(1) 
	INTO #tmp_nac_pas_aux
FROM BD_SIRIM.dbo.RimPasaporte pas
JOIN SimTramite st ON pas.sNumeroTramite = st.sNumeroTramite
WHERE
	pas.sEstado = 'ENTREGADA'
	AND EXISTS (SELECT 1 FROM #tmp_per_nac_with_uId nac WHERE nac.uIdPersona = st.uIdPersona)
GROUP BY
	st.uIdPersona

-- 2.3
SELECT 
	nac.nId,
	sper.sIdDocIdentidad,
	sper.sNumDocIdentidad,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.dFechaNacimiento,
	sper.sIdEstadoCivil,
	[sPaisNacimiento] = p1.sNacionalidad,
	[sPaisNacionalid] = p2.sNacionalidad,
	[sTipoMovMig] = (SELECT mm.sTipo FROM #tmp_nac_mm_aux mm WHERE mm.uIdPersona = nac.uIdPersona),
	[dFechaMovMig] = (SELECT mm.dFechaControl FROM #tmp_nac_mm_aux mm WHERE mm.uIdPersona = nac.uIdPersona),
	[sProcDest] = (SELECT mm.sIdPaisMov FROM #tmp_nac_mm_aux mm WHERE mm.uIdPersona = nac.uIdPersona),
	[sPuestoControl] = (SELECT sd.sNombre FROM #tmp_nac_mm_aux mm 
						JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
						WHERE mm.uIdPersona = nac.uIdPersona),
	[sEmpresaTrans] = (SELECT se.sNombreRazon FROM #tmp_nac_mm_aux mm 
					   JOIN SimEmpTransporte se ON mm.nIdTransportista = se.nIdTransportista
					   WHERE mm.uIdPersona = nac.uIdPersona),
	[sCalidadMig] = (SELECT scm.sDescripcion FROM #tmp_nac_mm_aux mm 
					   JOIN SimCalidadMigratoria scm ON mm.nIdCalidad = scm.nIdCalidad
					   WHERE mm.uIdPersona = nac.uIdPersona),

	[Fecha de Caducidad] = '',
	[Número de Carnet de extranjería] = '',

	[Ocupación] = sprof.sDescripcion,
	[RUCEmpresa] = '',
	[RazónSocialEmpresa] = '',
	[ObservacionesMovMig] = (SELECT mm.sObservaciones FROM #tmp_nac_mm_aux mm WHERE mm.uIdPersona = nac.uIdPersona),

	[Documento inválido] = sdi.sIdDocumento,
	[Número de  Documento  Inválido] = sdi.sNumDocInvalida,
	[Documento  de Alerta migratoria] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
	[Número  de Documento de Identidad de la alerta migratoria] = sper.sNumDocIdentidad,
	[Tipo Alerta migratoria] = stt.sDescripcion,

	[Descripción de la alerta migratoria] = smi.sDescripcion,
	[Observaciones de la alerta migratoria] = sdi.sObservaciones,
	[Cantidad de Pasaportes] = (SELECT pas.nTotalPas FROM #tmp_nac_pas_aux pas WHERE pas.uIdPersona = nac.uIdPersona)
FROM #tmp_per_nac_with_uId nac
JOIN SimPersona sper ON nac.uIdPersona = sper.uIdPersona
LEFT JOIN SimPais p1 ON sper.sIdPaisNacimiento = p1.sIdPais
LEFT JOIN SimPais p2 ON sper.sIdPaisNacionalidad = p2.sIdPais
LEFT JOIN SimProfesion sprof ON sper.sIdProfesion = sprof.sIdProfesion
LEFT JOIN SimPersonaNoAutorizada spna ON sper.sNombre = spna.sNombre 
									  AND sper.sPaterno = spna.sPaterno 
									  AND sper.sMaterno = spna.sMaterno
									  AND sper.sSexo = spna.sSexo
									  AND sper.dFechaNacimiento = spna.dFechaNacimiento
									  AND sper.sIdPaisNacionalidad = spna.sIdPaisNacionalidad
LEFT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
ORDER BY
	nac.nId

SELECT TOP 10 * FROM SimPersonaNoAutorizada WHERE nIdDocInvalidacion = 1550
SELECT TOP 100 * FROM SimDocInvalidacion WHERE nIdDocInvalidacion = 1232


SELECT 

	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),

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
	spna.bActivo
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente




SELECT * FROM SimPersona sper
WHERE
	-- sper.sNumDocIdentidad = '08270165'
	sper.uIdPersona IN (
		'6A7346F9-3195-49E0-AACE-1A2C9A1BFF4E',
		'4B855E68-DAF0-4E75-B4BA-B67522B1140E'
	)
--===========================================================================================================*/

-- ALB | ALBANIA
SELECT * FROM SimPais sp
WHERE sp.sNombre LIKE '%alba%'

SELECT 
	smm.sIdPaisNacionalidad,
	[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
	smm.sTipo,
	[nTOtal] = COUNT(11)
FROM SimMovMigra smm
WHERE 
	smm.bAnulado = 0
	AND smm.sIdPaisNacionalidad = 'ALB'
	AND smm.dFechaControl >= '2019-01-01 00:00:00.000'
GROUP BY
	smm.sIdPaisNacionalidad,
	DATEPART(YYYY, smm.dFechaControl),
	smm.sTipo
ORDER BY
	[nAñoControl]

SELECT * FROM BD_SIRIM.dbo.RimPasaporte p
WHERE p.sNumeroDNI = '40038603'

SELECT TOP 1 * FROM BD_SIRIM.dbo.RimPasaporte p
ORDER BY p.dFechaRegistro DESC



-- 0617C98F-E0FA-4432-8D7A-BDE50423DEB8	| HILL CRAIG ANTONY
SELECT * FROM SimPersona sper
WHERE
	sper.sNombre LIKE 'CRAIG ANT%'
	AND sper.sPaterno = 'HILL'


-- CCM
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	[sTipoTramite] = stt.sDescripcion,
	st.sNumeroTramite,
	st.dFechaHoraReg,
	sti.sEstadoActual,
	scm.dFechaAprobacion,
	scm.dFechaVencimiento
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimCambioCalMig scm ON st.sNumeroTramite = scm.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE 
	st.uIdPersona = '0617C98F-E0FA-4432-8D7A-BDE50423DEB8'
	AND st.nIdTipoTramite = 58


-- Test
-- DAVID ANDRÉS	ELGUETA	ORELLANA

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sorg.sNombre,
	sorg.*,
	se.*
FROM SimPersona sper
JOIN SimExtranjero se ON sper.uIdPersona = se.uIdPersona
JOIN SimOrganizacion sorg ON se.nIdOrganizacion = sorg.nIdOrganizacion 
WHERE
	/*sper.sNombre LIKE 'CRAIG ANT%'
	AND sper.sPaterno = 'HILL'*/
	sper.sNombre LIKE 'ALVARO'
	AND sper.sPaterno = 'VICENTE'
	AND sper.sMaterno = 'CATURLA'
	/*sper.sNombre LIKE 'FELIX%'
	AND sper.sPaterno LIKE 'FERNANDEZ'*/