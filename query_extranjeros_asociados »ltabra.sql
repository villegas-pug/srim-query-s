USE SIM
GO

/*»
	→ LUGAR : JR. LA LAGUNA Nº 275 – URB. LA PLANICIE – DISTRITO LA MOLINA
	→ PROPIETARIA INMUEBLE: MARIA LUISA, FRIEDRICH ESCALANTE (60) - (PERUANA
====================================================================================================================================================*/

SELECT 
	[sNombre] = sper.sNombre,
	[Paterno] = sper.sPaterno,
	[Materno] = sper.sMaterno,
	[Sexo] = sper.sSexo,
	[Fecha Nacimiento] = sper.dFechaNacimiento,
	[Pais Nacionalidad] = sper.sIdPaisNacionalidad,
	[Distrito Domicilio] = su.sNombre,
	[Dirección Domiciliaria] = se.sDomicilio,
	se.sTelefono,
	[Calidad Migratoria] = scm.sDescripcion,
	[Ultimo MovMigra] = (
							COALESCE(
							
								(SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
								WHERE
									smm.uIdPersona = se.uIdPersona
								ORDER BY
									smm.dFechaControl DESC),
								'Sin Control Migratorio'

							)
								
						)
FROM SimExtranjero se
JOIN SimPersona sper ON se.uIdPersona = sper.uIdPersona
LEFT JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
-- JOIN
WHERE
	-- se.sIdUbigeoDomicilio = '140101'
	-- se.sDomicilio LIKE '%JR%LAGUNA%275%PLANICIE%MOLINA%' -- LUGAR : JR. LA LAGUNA Nº 275 – URB. LA PLANICIE – DISTRITO LA MOLINA
	se.sDomicilio LIKE '%LAGUNA%275%PLANICIE%' -- LUGAR : JR. LA LAGUNA Nº 275 – URB. LA PLANICIE – DISTRITO LA MOLINA


-- Test ...
SELECT * FROM SimExtranjero se
WHERE
	-- se.sIdUbigeoDomicilio = '140101'
	-- se.sDomicilio LIKE '%JR%LAGUNA%275%PLANICIE%MOLINA%' -- LUGAR : JR. LA LAGUNA Nº 275 – URB. LA PLANICIE – DISTRITO LA MOLINA
	se.sDomicilio LIKE '%LAGUNA%'
	-- AND se.sDomicilio LIKE '%275%'
	AND se.sDomicilio LIKE '%PLANICIE%'
	AND se.sDomicilio LIKE '%MOLINA%'
	


-- 2
SELECT DATEDIFF(YYYY, '1963-07-04', GETDATE()) -- 60 años ...

SELECT sp.* FROM SimPersona sper
JOIN SimPeruano sp ON sper.uIdPersona = sp.uIdPersona
WHERE
	sper.sNombre = 'MARIA LUISA'
	AND sper.sPaterno = 'FRIEDRICH'
	AND sper.sMaterno = 'ESCALANTE'


-- SEIS (06) CIUDDADANOS TAIWUANESES DETENIDOS
-- Movimiento migratorios ...
SELECT 
	mm2.sNombres,
	mm2.sNumeroDoc,
	mm2.dFechaControl,
	mm2.sCalidad,
	mm2.sTipo,
	mm2.sIdPaisMov
FROM (

	SELECT 
		smm.*,
		[sCalidad] = scm.sDescripcion,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
	WHERE
		-- 1
		smm.sIdDocumento = 'PAS'
		AND smm.sNumeroDoc IN (
			'312711231',
			'360183024',
			'313321277',
			'360534423',
			'312411758',
			'360487304'
		)

) mm2
WHERE
	mm2.nFila_mm = 1

/*
	→ Lo q hay que verificar esq en el vuelo q vinieron esos 3 , que otros ciudadanos taiwaneses (o chinos) tb vinieron
*/

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	smm.sNumeroDoc,
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdPaisNacionalidad,
	smm.sIdPaisNacimiento,
	smm.sIdPaisMov,
	[sNumeroVuelo] = si.sIdItinerario,
	si.sNumeroNave,
	si.dFechaProgramada,
	[sUltimoMovMigra] = (
	
		SELECT TOP 1 smm2.sTipo FROM SimMovMigra smm2 
		WHERE 
			smm2.uIdPersona = smm.uIdPersona
		ORDER BY
			smm2.dFechaControl DESC
	
	)
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
WHERE
	-- 1
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	-- 1. TWN | TAIWAN 2. CHN | CHINA
	AND smm.sIdPaisNacionalidad IN ('TWN', 'CHN')
	AND  smm.sIdItinerario IN (
	
		SELECT 
			DISTINCT
			mm2.sIdItinerario -- Vuelo ...
		FROM (

			SELECT 
				smm.sIdItinerario,
				[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
			FROM SimMovMigra smm
			WHERE
				-- 1
				smm.sIdDocumento = 'PAS'
				AND smm.sNumeroDoc IN (
					'312711231',
					'360183024',
					'313321277',
					'360534423',
					'312411758',
					'360487304'
				)

		) mm2
		WHERE
			mm2.nFila_mm = 1

	)

-- ===================================================================================================================================================

USE SIM
GO

SELECT 
	mm.*,
	[nIdCalidad] = cm.nIdCalidad,
	[sCalidad] = cm.sDescripcion
FROM SimMovMigra mm
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
	mm.bAnulado = 0
	AND mm.bTemporal = 0