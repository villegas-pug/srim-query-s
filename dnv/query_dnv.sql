/*
	→ Ciudadanos de nacionalidad india, marroquí y libanesa
	→ Periodo 15/03/2020 en adelante
*/

DECLARE 
       @nacionalidad VARCHAR(100) = '<<valor>>',
	   @dependencia VARCHAR(100) = '<<valor>>',
	   @tipoMov VARCHAR(15) = '<<valor>>',
       @fechaMovMigIni DATETIME = '<<valor>>',
       @fechaMovMigFin DATETIME = '<<valor>>'

/*
	░ Ver 1.1
	► RESIDENTE = TRABAJADOR | INMIGRANTE = INMIGRANTE | PERMANENTE O FAMILIAR RESIDENTE = RESIDENTE
*/
/*----------------------------------------------------------------------------------------------------------------------*/	
SELECT
	(smm.sIdDocumento)Documento,
	(smm.sNumeroDoc)Numero_Documento,
	(sp.sNombre)Nombre,
	(sp.sPaterno)Ape_Pat,
	(sp.sMaterno)Ape_Mat,
	(sp.sSexo)Sexo,
	(sp.dFechaNacimiento)Fecha_Nacimiento,
	(spnacimiento.sNombre)Pais_Nacimiento,
	(spnacionalidad.sNombre)Pais_Nacionalidad,
	(smm.sTipo)Tipo_Movimiento,
	(smm.dFechaControl)Fecha_Control,
	sope.sLogin Login_Operador_Digita,
	sope.sNombre Operador_Digita,
	(spaismov.sNombre)Procedencia_Destino,
	(sd.sNombre)Dependencia_Digita,
	(setran.sNombreRazon)Empresa_Transporte,
	(scm.sDescripcion)Calidad_Migratoria,
	smm.bAnulado [MovMig_Anulado],
	
	(sce.sNumeroCarnet)Numero_Carnet,
	(sce.dFechaCaducidad)Fecha_Caducidad,
	(sprof.sDescripcion)Ocupacion,
	(sorg.sNombre)Razon_Social_Empresa,
	(sorg.sNumeroDoc)Ruc_Empresa,
	(sp.sIdEstadoCivil)Estado_Civil,

	su.sIdUbigeo Id_Ubigeo,
	(
		(SELECT sNombre FROM SimUbigeo WHERE sCodAnterior = LEFT(su.sIdUbigeo, 2)) + ' - ' +
		(SELECT sNombre FROM SimUbigeo WHERE sCodAnterior = LEFT(su.sIdUbigeo, 4)) + ' - ' +
		(su.sNombre)
	)Ubigeo,
	se.sDomicilio Domicilio,
	
	(smm.sObservaciones)Observaciones_SIM_RCM,
	(sdi.sIdDocInvalida)Doc_Invalida,
	(sdi.sNumDocInvalida)Numero_Doc_Invalida,
	(sdi.nTipoAlerta)Tipo_Alerta,
	(spna.sDescripcion)Descripcion,
	(spna.sObservaciones)Observaciones,

	smv.sDescripcion Motivo_Viaje,
	smm.sObservaciones Observaciones_MovMigra,
	ssa.sNumeroDoc Documento_Autoridad_Viaje,
	ssa.dFechaEmision Fec_Emision_SalidaAutorizada,
	ssa.sObservaciones Obervaciones_SalidaAutorizada,
	ssa.sNombreAutoridad NombreAutoridad_SalidaAutorizada,
	sta.sDescripcion Tipo_Autoridad
FROM SimMovMigra smm 
JOIN SimPersona sp ON sp.uIdPersona = smm.uIdPersona
LEFT OUTER JOIN SimUsuario sope ON smm.nIdOperadorDigita = sope.nIdOperador
LEFT OUTER JOIN SimPersonaNoAutorizada spna ON smm.sNumeroDoc = spna.sNumDocIdentidad
LEFT OUTER JOIN SimProfesion sprof ON sp.sIdProfesion = sprof.sIdProfesion
LEFT OUTER JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT OUTER JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
LEFT OUTER JOIN SimCarnetExtranjeria sce ON sp.uIdPersona = sce.uIdPersona
LEFT OUTER JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
LEFT OUTER JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT OUTER JOIN SimOrganizacion sorg ON se.nIdOrganizacion = sorg.nIdOrganizacion
LEFT OUTER JOIN SimEmpTransporte setran ON smm.nIdTransportista = setran.nIdTransportista
LEFT OUTER JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
LEFT OUTER JOIN SimPais spnacimiento ON sp.sIdPaisNacimiento = spnacimiento.sIdPais
LEFT OUTER JOIN SimPais spnacionalidad ON sp.sIdPaisNacionalidad = spnacionalidad.sIdPais
LEFT OUTER JOIN SimPais spaismov ON smm.sIdPaisMov = spaismov.sIdPais
LEFT OUTER JOIN SimMotivoViaje smv ON smm.nIdMotivoViaje = smv.nIdMotivoViaje
LEFT OUTER JOIN SimSalidaAutorizada ssa ON smm.sIdMovMigratorio = ssa.sIdMovMigratorio
LEFT OUTER JOIN SimTipoAutoridad sta ON ssa.nIdTipoAutoridad = sta.nIdTipoAutoridad
WHERE
	--smm.bAnulado = 0
	sce.bAnulado = 0
	AND smm.dFechaControl BETWEEN '2022-01-01 00:00:00' AND '2022-12-31 23:59:59'
	--AND sp.sIdPaisNacionalidad IN ('AFG', 'ARL', 'BAN', 'DJI', 'EGI', 'ERI', 'IRN', 'IRK', 'MLI', 'MAT', 'NIA', 'CNO', 'OMA', 'PAK', 'QAT', 'SOM', 'SUD', 'SIR', 'TUN', 'TRK', 'YRA')
	AND smm.sIdPaisNacionalidad = 'NEP'
	--AND sp.sNombre = 'ZHIYI'
	--AND sp.sPaterno = 'AN'
	--AND smm.sIdDependencia = @dependencia
	--AND smm.sTipo = @tipoMov

	/*
	░ Ver 1.2
	► RESIDENTE = TRABAJADOR | INMIGRANTE = INMIGRANTE | PERMANENTE O FAMILIAR RESIDENTE = RESIDENTE
*/
/*----------------------------------------------------------------------------------------------------------------------*/	
;WITH cte AS (
	SELECT
		(smm.dFechaControl)Fecha_Control,
		(smm.sTipo)Tipo_Movimiento,
		(scm.sDescripcion)Calidad_Migratoria,
		(sp.sNombre + ', ' + sp.sPaterno + ' ' + sp.sMaterno)Ciudadano,
		(sp.sSexo)Sexo,
		(sp.dFechaNacimiento)Fecha_Nacimiento,
		(sp.sIdPaisNacionalidad)Pais_Nacionalidad,
		(sp.sIdEstadoCivil)Estado_Civil,
		
		smv.sDescripcion Motivo_Viaje,
		(sprof.sDescripcion)Ocupacion_Persona,
		(sprofe.sDescripcion)Ocupacion_Extranjero,
		(sorg.sNombre)Razon_Social_Empresa,
		(sorg.sNumeroDoc)Ruc_Empresa,
		smm.sObservaciones Observaciones_MovMigra,
		ROW_NUMBER() OVER (PARTITION BY sp.uIdPersona ORDER BY smm.dFechaControl DESC) nRow
	FROM SimMovMigra smm 
	JOIN SimPersona sp ON sp.uIdPersona = smm.uIdPersona
	LEFT JOIN SimProfesion sprof ON sp.sIdProfesion = sprof.sIdProfesion
	LEFT JOIN SimExtranjero se ON sp.uIdPersona = se.uIdPersona
	LEFT JOIN SimProfesion sprofe ON se.sIdProfesionOcupacion = sprofe.sIdProfesion
	LEFT JOIN SimOrganizacion sorg ON se.nIdOrganizacion = sorg.nIdOrganizacion
	LEFT JOIN SimEmpTransporte setran ON smm.nIdTransportista = setran.nIdTransportista
	LEFT JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
	LEFT JOIN SimMotivoViaje smv ON smm.nIdMotivoViaje = smv.nIdMotivoViaje
	WHERE
		smm.bAnulado = 0
		AND smm.sTipo = 'E'
		AND smm.sIdPaisNacionalidad = 'VEN'
		--AND sp.uIdPersona != ''
		AND smm.dFechaControl BETWEEN '2017-01-01 00:00:00' AND '2018-12-31 23:59:59'
), cte2 AS (
	SELECT * FROM cte WHERE cte.nRow = 1
) SELECT * FROM cte2
/*----------------------------------------------------------------------------------------------------------------------------------------------*/



/*► DNV 2.0 ... */
SELECT
	(spna.sNombre)Nombre,
	(spna.sPaterno)Ape_Pat,
	(spna.sMaterno)Ape_Mat,
	(spna.sSexo)Sexo,
	(spna.dFechaNacimiento)Fecha_Nacimiento,
	(spnacimiento.sNombre)Pais_Nacimiento,
	(spnacionalidad.sNombre)Pais_Nacionalidad,
	sdi.dFechaEmision [Fecha_Invalidación],
	smi.sDescripcion Motivo_Invalidación,
	(sdi.sIdDocInvalida)Doc_Invalidación,
	(sdi.sNumDocInvalida)Numero_Doc_Invalidación,
	(sdi.sObservaciones)Observaciones_Invalidacion,
	(sdi.nTipoAlerta)Tipo_Alerta,
	(spna.sDescripcion)Descripcion_Persona_No_Autorizada,
	(spna.sObservaciones)Observaciones_Persona_No_Autorizada,

	/*► Operador: */
	su.sLogin sLoginOperador,
	su.sNombre sOperadorDigita,
	sd.sNombre sDependenciaDigita

	--sdi.nIdSesion [sdi],
	--spna.nIdSesion [spna]
FROM SimDocInvalidacion sdi 
JOIN SimPersonaNoAutorizada spna ON sdi.nIdDocInvalidacion = spna.nIdDocInvalidacion
JOIN SimSesion ss ON sdi.nIdSesion = ss.nIdSesion
JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
JOIN SimDependencia sd ON su.sIdDependencia = sd.sIdDependencia
LEFT JOIN SimMotivoInvalidacion smi ON smi.sIdMotivoInv = spna.sIdMotivoInv
LEFT JOIN SimPais spnacimiento ON spna.sIdPaisNacimiento = spnacimiento.sIdPais
LEFT JOIN SimPais spnacionalidad ON spna.sIdPaisNacionalidad = spnacionalidad.sIdPais

/*► Test: Cancelación de Movimiento Migratorio ...*/
/*---------------------------------------------------------------------------------------------------*/

SELECT 
	sOpeCancela.* 
FROM SimMovMigra smm 
JOIN SimCancelacionMov scm ON smm.sIdMovMigratorio = scm.sIdMovMigratorio
JOIN SimMotivoTramite smt ON scm.nIdMotivoTramite = smt.nIdMotivoTramite
JOIN SimSesion ssOpeCancela ON scm.nIdSesion = ss.nIdSesion
Join SimUsuario sOpeCancela ON ss.nIdOperador = sOpeCancela.nIdOperador
WHERE smm.uIdPersona = '386CD80D-6985-46EA-84F4-6857D31280EA' AND smm.bAnulado = 1

/*► Buscar persona: */
SELECT * FROM SimPersona spna WHERE spna.sNombre LIKE '%CARLOS%' AND spna.sPaterno LIKE '%AGUILAR%' AND spna.sMaterno LIKE '%ORTIZ%'

/*---------------------------------------------------------------------------------------------------*/






BACKUP DATABASE TEST2
TO DISK = '\\10.30.30.156\eromero\SIM.bak'
--TO DISK = N'E:\eromero\TEST2.bak'
WITH NOFORMAT, NOINIT, NAME = N'TEST2',
STATS = 1

SELECT COUNT(1) FROM SimMovMigra

BACKUP DATABASE RIMSIM
TO DISK = '\\172.27.250.14\backup_sim\SIM.bak'
--TO DISK = N'E:\eromero\SIM.bak'
WITH INIT, COMPRESSION, NAME = N'SIM',
STATS = 1

