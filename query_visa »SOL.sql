USE SIM
GO

-- SELECT * FROM SimTipoTramite stt WHERE stt.nIdTipoTramite = 55

-- 55 | SOLICITUD DE CALIDAD MIGRATORIA
/*
	Campos:
		N� DE EXPEDIENTE
		FECHA FIN
		TIPO DE PROCEDIMIENTO
		NOMBRES
		APELLIDOS
		NACIONALIDAD
		SEXO, EDAD, FECHA DE NACIMIENTO, DOMICILIO DECLARADO, FECHA DE INGRESO, ULT.MOV.MIG.FEC, ULT.MOV.MIG.TIPO, ULT.MOV.MIG.PA�S, CORREO REGISTRADO

	Pais:
		SIR | SIRIA
		SRI	| SRI LANKA
		SAM	| SAMOA OCCIDENTAL
*/

-- 1: ...
SELECT 

	-- Datos tr�mite ...
	[Número Tramite] = st.sNumeroTramite,
	[Año Tramite] = DATEPART(YYYY, st.dFechaHora),
	[Estado Actual Tramite] = sti.sEstadoActual,
	[Calidad] = scm.sDescripcion,
	[Tiempo otorgado SOLVISA] = sv.nTiempo,
	[Tipo tiempo otorgado SOLVISA] = sv.sTipoTiempo,
	[Fecha Inicio Vigencia] = sv.dFechaInicioVigencia,
	[Fecha Aprobacion] = sv.dFechaAprobacion,
	-- [Fecha Fin Vigencia] = sv.dFechaFinVigencia,
	-- [Fecha Vencimiento] = sv.dFechaVencimiento,
	[Motivo SOLVISA] = sm.sDescripcion,

	-- Datos personales ...
	-- sper.uIdPersona,
	[Paterno] = sper.sPaterno,
	[Materno] = sper.sMaterno,
	[Nombre] = sper.sNombre,
	[Sexo] = sper.sSexo,
	[Fecha Nacimiento] = sper.dFechaNacimiento,
	[Pais Nacionalidad] = sp.sNombre,
	[Doc Identidad] = sper.sIdDocIdentidad,
	[Num Doc Identidad] = CONCAT('''', sper.sNumDocIdentidad),

	-- Evaluador `APRUEBA` ...
	[Evaluador SOLVISA] = (
								SELECT TOP 1 su.sNombre FROM SimEtapaTramiteInm seti
								JOIN SimUsuario su ON seti.nIdUsrInicia = su.nIdOperador
								WHERE
									seti.sNumeroTramite = st.sNumeroTramite
									AND seti.bActivo = 1
									AND seti.nIdEtapa = 22 -- CONFORMIDAD SUB-DIREC.INMGRA. | 22
									AND seti.sEstado = 'F'
								ORDER BY
									seti.dFechaHoraFin DESC
						 ),

	-- Control Migratorio ...
	[Fecha Ultimo MovMigra] = COALESCE(
											(
												SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
												WHERE
													smm.uIdPersona = st.uIdPersona
													AND smm.bAnulado = 0
													AND smm.bTemporal = 0
												ORDER BY
													smm.dFechaControl DESC
											),
											NULL
							 			),
	[Tipo Ultimo MovMigra] = COALESCE(
										(
											SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
											WHERE
												smm.uIdPersona = st.uIdPersona
												AND smm.bAnulado = 0
												AND smm.bTemporal = 0
											ORDER BY
												smm.dFechaControl DESC
										),
										'Sin Control Migratorio'
									),
	[Fecha MovMigra (Posterior SOLVISA)] = COALESCE(
															(
																SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
																WHERE
																	smm.uIdPersona = st.uIdPersona
																	AND smm.bAnulado = 0
																	AND smm.bTemporal = 0
																	AND smm.dFechaControl >= sv.dFechaAprobacion
																ORDER BY
																	smm.dFechaControl DESC
															),
															NULL
														),
	[Tipo MovMigra (Posterior SOLVISA)] = COALESCE(
															(
																SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
																WHERE
																	smm.uIdPersona = st.uIdPersona
																	AND smm.bAnulado = 0
																	AND smm.bTemporal = 0
																	AND smm.dFechaControl >= sv.dFechaAprobacion
																ORDER BY
																	smm.dFechaControl DESC
															),
															'Sin Control Migratorio'
														),
	[Fecha MovMigra (Anterior SOLVISA)] = COALESCE(
															(
																SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
																WHERE
																	smm.uIdPersona = st.uIdPersona
																	AND smm.bAnulado = 0
																	AND smm.bTemporal = 0
																	AND smm.dFechaControl < sv.dFechaAprobacion
																ORDER BY
																	smm.dFechaControl DESC
															),
															NULL
									 					),
	[Tipo MovMigra (Anterior SOLVISA)] = COALESCE(
														(
															SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
															WHERE
																smm.uIdPersona = st.uIdPersona
																AND smm.bAnulado = 0
																AND smm.bTemporal = 0
																AND smm.dFechaControl < sv.dFechaAprobacion
															ORDER BY
																smm.dFechaControl DESC
														),
														'Sin Control Migratorio'
													),

	[Tramites Posteriores SOLVISA] = COALESCE(
													(
														SELECT stt2.sDescripcion, sti2.sEstadoActual FROM SimTramite st2
														JOIN SimTramiteInm sti2 ON st2.sNumeroTramite = sti2.sNumeroTramite
														JOIN SimTipoTramite stt2 ON st2.nIdTipoTramite = stt2.nIdTipoTramite
														WHERE
															st2.uIdPersona = st.uIdPersona
															AND st2.dFechaHora > sv.dFechaAprobacion
														FOR XML PATH('')
													),
													'Sin Trámites'
												)

FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
LEFT JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimPais sp ON sper.sIdPaisNacionalidad = sp.sIdPais
JOIN SimVisa sv ON st.sNumeroTramite = sv.sNumeroTramite
JOIN SimCalidadMigratoria scm ON sv.nIdCalSolicitada = scm.nIdCalidad
JOIN SimMotivo sm ON sv.nIdMotivo = sm.nIdMotivo
WHERE
	st.bCancelado = 0
	AND st.nIdTipoTramite = 55 -- SOLICITUD DE CALIDAD MIGRATORIA
	-- AND st.dFechaHora BETWEEN '2022-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
	AND st.dFechaHora >= '2022-01-01 00:00:00.000'
	AND sti.sEstadoActual = 'A'
	-- AND sper.sIdPaisNacionalidad IN ('SIR', 'SRI', 'SAM')

-- =========================================================================================================================





-- Test ...
SELECT * FROM SimTipoTramite stt FOR XML RAW, ELEMENTS

USE SIM
GO

SELECT
	smm.*
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.sIdPaisNacionalidad = 'PER'
	AND (smm.sNombres != '' AND smm.sNombres IS NOT NULL)


-- Test ...
SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%chi%'


EXEC sp_help SimTramiteInm

SELECT 
	sti.sNumeroTramite, 
	[Empresa] = so.sNombre,
	[Provincia / Distrito] = su.sNombre,
	[Dirección Empresa] = so.sDireccion
FROM SimTramiteInm sti
JOIN SimOrganizacion so ON sti.nIdOrganizacion = so.nIdOrganizacion
JOIN SimUbigeo su ON so.sIdUbigeo = su.sIdUbigeo
WHERE
	sti.sNumeroTramite IN 
	(
		'LM230108249',
		'LM230147294',
		'LM230147768',
		'LM230147454',
		'LM230109098',
		'LM230147340',
		'LM230195789',
		'LM230108282',
		'LM230147510',
		'LM230147817',
		'LM230147273',
		'LM230361460'
	)


	SELECT * FROM SimPersona sper
	WHERE
		sper.sIdDocIdentidad = 'CPP'
		AND sper.sNumDocIdentidad = '002731444'
		-- AND sper.sNumDocIdentidad = '1010610'

