USE SIM
GO

/*░

	STEP-01 → Extraer extranjeros permanecen en territorio nacional

	Campos de extracción:
	ID PERSONA, NOMBRE, APELLIDO PATERNO, APELLIDO MATERNO, SEXO, FECHA NACIMIENTO, NACIONALIDAD, TIPO DE DOCUMENTO, NÚMERO DE DOCUMENTO,
	TIPO DE CONTROL ÚLTIMO MOVIMIENTO, FECHA DE CONTROL ÚLTIMO MOVIMIENTO, RUTA, CALIDAD MIGRATORIA, TRAMITE DE CALIDAD MIGRATORIA VINCULADO AL REGISTRO,
	DATOS BIOMETRICOS, DNV
 
*/

-- » 1.1: Extrae ciudadanos extranjeros permanecen en terririo nacional ...

DROP TABLE IF EXISTS #tmp_ultimo_ctrlmig
SELECT * INTO #tmp_ultimo_ctrlmig FROM (

	SELECT 
		smm.uIdPersona,

		-- MovMig
		[sTipoControl] = smm.sTipo,
		smm.dFechaControl,
		[sRuta] = smm.sIdPaisMov,
		smm.nIdCalidad,
		[sDocumentoViaje] = smm.sIdDocumento,
		[sNumeroDocumentoViaje] = smm.sNumeroDoc,

		-- Aux
		[nRow_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)

	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjeros ...
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

) mm
WHERE
	mm.nRow_mm = 1
	-- AND mm.sTipoControl = 'E'

-- Test
SELECT COUNT(1) FROM #tmp_ultimo_ctrlmig

-- » 1.2: 
DROP TABLE IF EXISTS #tmp_ultimo_ctrlmig_adicional
SELECT 
	mm.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacionalidad,
	sp.sIdDocIdentidad,
	sp.sNumDocIdentidad,

	-- MovMig
	mm.[sTipoControl],
	mm.dFechaControl,
	[sRuta] = IIF(mm.sTipoControl = 'E', CONCAT(spruta.sNombre, '-PERU'), CONCAT('PERU-', spruta.sNombre)),
	[sCalidad] = scm.sDescripcion,

	-- Tramites CCM
	[¿Tiene CCM?] = IIF(
						EXISTS(SELECT 1 FROM SimTramite st
							   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
						       WHERE st.uIdPersona = mm.uIdPersona AND st.nIdTipoTramite = 58 AND sti.sEstadoActual = 'A'),
						'Si',
						'No'
					),
	[¿Tiene Biometría?] = IIF(
								EXISTS(SELECT TOP 1 1 FROM SimImagen si WHERE mm.uIdPersona = sp.uIdPersona),
								'Si',
								'No'
							),
	[¿Tiene DNV?] = IIF(
						EXISTS(
							SELECT TOP 1 1 FROM SimPersonaNoAutorizada spna
							JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
							WHERE
								spna.sNumDocIdentidad = sp.sNumDocIdentidad
								AND spna.sIdPaisNacionalidad = sp.sIdPaisNacionalidad
						),
						'Si',
						'No'
						)

	INTO #tmp_ultimo_ctrlmig_adicional
FROM #tmp_ultimo_ctrlmig mm
JOIN SimPersona sp ON sp.uIdPersona = mm.uIdPersona
JOIN SimPais spnac ON sp.sIdPaisNacionalidad = spnac.sIdPais
JOIN SimPais spruta ON mm.sRuta = spruta.sIdPais
JOIN SimCalidadMigratoria scm ON mm.nIdCalidad = scm.nIdCalidad



-- » 1.3: Agrupa a ciudadanos extranjeros con atributos identicos ...
-- SELECT TOP 1 * FROM #tmp_ultimo_ctrlmig_adicional
DROP TABLE IF EXISTS #tmp_ctrlmig_permanecen_group
SELECT 
	cm.sPaterno,
	cm.sMaterno,
	cm.dFechaNacimiento,
	cm.sIdPaisNacionalidad,
	cm.sSexo,

	[nCantCoincidencia] = COUNT(1)

	INTO #tmp_ctrlmig_permanecen_group
FROM #tmp_ultimo_ctrlmig_adicional cm
GROUP BY
	cm.sPaterno,
	cm.sMaterno,
	cm.dFechaNacimiento,
	cm.sIdPaisNacionalidad,
	cm.sSexo
HAVING
	COUNT(1) > 1

-- Test
SELECT COUNT(1) FROM #tmp_ctrlmig_permanecen_group g
SELECT COUNT(1) FROM #tmp_ultimo_ctrlmig_adicional

SELECT SUM(g.nCantCoincidencia) FROM #tmp_ctrlmig_permanecen_group g

-- » 1.3: Extrae extranjeros que permanecen en le perú, con más de 1 identidad ...
DROP TABLE IF EXISTS tmp_ctrlmig_mas1identidad
SELECT * INTO tmp_ctrlmig_mas1identidad FROM #tmp_ultimo_ctrlmig_adicional p
WHERE
	EXISTS(

		SELECT 1 FROM #tmp_ctrlmig_permanecen_group g
		WHERE
			p.sPaterno = g.sPaterno AND p.sMaterno = g.sMaterno
			AND p.dFechaNacimiento = g.dFechaNacimiento
			AND p.sIdPaisNacionalidad = g.sIdPaisNacionalidad
			AND p.sSexo = g.sSexo

	)
ORDER BY
	p.sPaterno,
	p.sMaterno,
	p.dFechaNacimiento,
	p.sIdPaisNacionalidad,
	p.sSexo

-- Test 
SELECT TOP 100 * FROM tmp_ctrlmig_mas1identidad p
ORDER BY
	p.sPaterno,
	p.sMaterno,
	p.dFechaNacimiento,
	p.sIdPaisNacionalidad,
	p.sSexo
SELECT COUNT(1) FROM tmp_ctrlmig_mas1identidad










/*░ Todos datos relacionados al ciudadano ...
	
	- Herman Lester Pezo Renteria
*/

-- STEP-1: Identidades
SELECT 
	sp.uIdPersona, 
	sp.sNombre, 
	sp.sMaterno, 
	sp.sPaterno, 
	sp.dFechaNacimiento, 
	sp.sSexo, 
	sp.sIdDocIdentidad, 
	sp.sNumDocIdentidad,
	sp.sIdPaisNacionalidad
FROM SimPersona sp
WHERE
	sp.sNombre LIKE '%LESTER%'
	AND sp.sPaterno LIKE '%PE%' 
	AND sp.sMaterno LIKE '%RENT%'

-- 4E5F5829-FC50-4EFF-AFC6-DF02C420B257

-- STEP-2
-- 2.1: Trámites
SELECT 
	st.uIdPersona,
	st.sNumeroTramite,
	st.dFechaHoraReg,
	[sTipoTramite] = stt.sDescripcion,
	st.sObservaciones
FROM SimTramite st
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	st.uIdPersona = '4E5F5829-FC50-4EFF-AFC6-DF02C420B257'

-- 2.1: MovMigra
SELECT
			-- Group-01
			smm.uIdPersona,
			[Tipo Documento Viaje] = (smm.sIdDocumento),
			[Numero Documento Viaje] = '''' + (smm.sNumeroDoc),
			[Tipo Movimiento] = (smm.sTipo),
			[Fecha Control] = (smm.dFechaControl),
			[Calidad Migratoria Viaje] = scm.sDescripcion,

			-- Group-03
			[Observaciones SIM_RCM] = (smm.sObservaciones),
			[Tipo Documento Invalida] = (sdi.sIdDocInvalida),
			[Numero Documento Invalida] = '"' + sdi.sNumDocInvalida,
			[Tipo Alerta] = (sdi.nTipoAlerta),
			[Descripcion Persona No Autorizada] = (spna.sDescripcion),
			[Observaciones Persona No Autorizada] = (spna.sObservaciones),

			[Motivo Viaje] = smv.sDescripcion,
			[Observaciones MovMigra] = smm.sObservaciones,
			[Documento Autoridad Viaje] = ssa.sNumeroDoc,
			[Fec_Emision Salida Autorizada] = ssa.dFechaEmision,
			[Obervaciones Salida Autorizada] = ssa.sObservaciones,
			[NombreAutoridad Salida Autorizada] = ssa.sNombreAutoridad,
			[Tipo Autoridad] = sta.sDescripcion
			-- INTO #mm_dnv
			-- DROP TABLE IF EXISTS #mm_dnv
		FROM SimMovMigra smm 
		LEFT OUTER JOIN SimPersonaNoAutorizada spna ON smm.sNumeroDoc = spna.sNumDocIdentidad
		LEFT OUTER JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
		LEFT OUTER JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
		LEFT OUTER JOIN SimMotivoViaje smv ON smm.nIdMotivoViaje = smv.nIdMotivoViaje
		LEFT OUTER JOIN SimSalidaAutorizada ssa ON smm.sIdMovMigratorio = ssa.sIdMovMigratorio
		LEFT OUTER JOIN SimTipoAutoridad sta ON ssa.nIdTipoAutoridad = sta.nIdTipoAutoridad
	WHERE
		smm.bAnulado = 0
		AND smm.uIdPersona = '4E5F5829-FC50-4EFF-AFC6-DF02C420B257'

-- 2.3: Pasaportes
SELECT 
	st.uIdPersona,
	[sTipoTramite] = stt.sDescripcion,
	spas.sPasNumero,
	spas.dFechaEmision,
	spas.dFechaExpiracion,
	spas.sEstadoActual,
	spas.sObservaciones
FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	st.uIdPersona = '4E5F5829-FC50-4EFF-AFC6-DF02C420B257'

SELECT 
	st.uIdPersona,
	[sTipoTramite] = stt.sDescripcion,
	pas.sNumeroPasaporte,
	pas.dFechaEmision,
	pas.dFechaCaducidad,
	pas.sEstado
FROM BD_SIRIM.dbo.RimPasaporte pas
LEFT JOIN SimTramite st ON pas.sNumeroTramite = st.sNumeroTramite
LEFT JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	pas.sNumeroDNI = '05288399'

-- 2.4: Multas
SELECT
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdPaisNacionalidad,
	sop.nTotal,
	sopd.nImporte,
	sopd.sNumeroTramite,
	scp.Descripcion [sConceptoPago],
	sm.sDescripcion [sMotivo],
	stm.sDescripcion [sTipoMotivo]
FROM SimMovMigra smm
JOIN SimOrdenPago sop ON smm.sIdMovMigratorio = sop.sIdMovMigratorio
LEFT JOIN SimOrdenPagoDetalle sopd ON sop.nIdPago = sopd.nIdPago
LEFT JOIN SimPConceptoPago scp ON sopd.nIdConcepto = scp.IdConceptoPago
LEFT JOIN SimMotivo sm ON scp.nIdMotivo = sm.nIdMotivo
LEFT JOIN SimTipoMotivo stm ON sm.nIdTipoMotivo = stm.nIdTipoMotivo
WHERE
	smm.uIdPersona = '4E5F5829-FC50-4EFF-AFC6-DF02C420B257'

