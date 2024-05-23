/*► Procedimiento almacenado DNV */
/*======================================================================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Rim_Utilitario_Dnv
(
	@nacionalidad VARCHAR(3), --PER
	@dependencia VARCHAR(3), --25
	@tipoMov VARCHAR(1), -- E | S | %
	@fecIniMovMig DATETIME, -- 2022-01-01
	@fecFinMovMig DATETIME -- 2022-01-01
)
AS
BEGIN
	/*► Dep's */
	/*DECLARE @dtFecIniMovMig DATETIME = CONCAT(@fecIniMovMig, ' 00:00:00'),
			@dtFecFinMovMig DATETIME = CONCAT(@fecFinMovMig, ' 23:59:59')*/

	/*► Repo: ... */
	/*======================================================*/
	DROP TABLE IF EXISTS #estadia_migratoria
	CREATE TABLE #estadia_migratoria
	(
		[uIdPersona] UNIQUEIDENTIFIER,
		[Tipo_Calidad_Migratoria] VARCHAR(55) NULL,
		[Calidad_Migratoria] VARCHAR(55) NULL,
		[Fecha_Inicio_Calidad_Migratoria] DATE NULL,
		[Fecha_Vencimiento_Calidad_Migratoria] DATE NULL
	)
	/*======================================================*/


	/*► STEP-01: Guardar `MovMig` en tabla temporal ... */
	DROP TABLE IF EXISTS #mm_dnv
	SELECT
		-- Group-01
		sp.uIdPersona,
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

		-- Group-02
		--(sce.sNumeroCarnet)Numero_Carnet,
		--(sce.dFechaCaducidad)Fecha_Caducidad,
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
	
		-- Group-03
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
		INTO #mm_dnv
	FROM SimMovMigra smm 
	LEFT OUTER JOIN SimPersona sp ON sp.uIdPersona = smm.uIdPersona
	LEFT OUTER JOIN SimUsuario sope ON smm.nIdOperadorDigita = sope.nIdOperador
	LEFT OUTER JOIN SimPersonaNoAutorizada spna ON smm.sNumeroDoc = spna.sNumDocIdentidad
	LEFT OUTER JOIN SimProfesion sprof ON sp.sIdProfesion = sprof.sIdProfesion
	LEFT OUTER JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
	LEFT OUTER JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
	--LEFT OUTER JOIN SimCarnetExtranjeria sce ON sp.uIdPersona = sce.uIdPersona
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
		smm.bAnulado = 0
		--AND sce.bAnulado = 0
		AND smm.sTipo LIKE @tipoMov
		AND smm.dFechaControl BETWEEN @fecIniMovMig AND @fecFinMovMig
		AND smm.sIdDependencia LIKE @dependencia
		AND smm.sIdPaisNacionalidad LIKE  @nacionalidad
		
	CREATE NONCLUSTERED INDEX ix_mm_dnv_uIdPersona
	ON #mm_dnv(uIdPersona)

	/*► STEP-02: Guardar `Ciudadanos` en tabla temporal ... */
	SELECT DISTINCT mm.uIdPersona INTO #dnv_ciudadanos FROM #mm_dnv mm

	CREATE NONCLUSTERED INDEX ix_dnv_ciudadanos
	ON #dnv_ciudadanos(uIdPersona)

	/*► STEP-03:  ... */
	WHILE (SELECT COUNT(1) FROM #dnv_ciudadanos) > 0
	BEGIN
		DECLARE @uId UNIQUEIDENTIFIER = (SELECT TOP 1 uIdPersona FROM #dnv_ciudadanos ORDER BY uIdPersona)

		INSERT INTO #estadia_migratoria
			EXEC usp_Rim_Utilitario_Estadia_Migratoria @uId

		/*► Eliminar ciudadano ...*/
		DELETE FROM #dnv_ciudadanos WHERE uIdPersona = @uId
	END

	CREATE NONCLUSTERED INDEX ix_estadia_migratoria_uIdPersona
	ON #estadia_migratoria(uIdPersona)


	/*► STEP-04: Join #mm_dnv y #estadia_migratoria */
	SELECT 
		es.Tipo_Calidad_Migratoria,
		es.Calidad_Migratoria,
		es.Fecha_Inicio_Calidad_Migratoria,
		es.Fecha_Vencimiento_Calidad_Migratoria,
		mm.* 
	FROM #mm_dnv mm
	LEFT OUTER JOIN #estadia_migratoria es ON mm.uIdPersona = es.uIdPersona

	/*► Clean-up ...*/
	DROP TABLE IF EXISTS #mm_dnv
	DROP TABLE IF EXISTS #dnv_ciudadanos
	DROP TABLE IF EXISTS tmp_estadia_migratoria

END

/*► Test ... */
EXEC dbo.usp_Rim_Utilitario_Dnv '%', '%', '%', '2020-01-01 00:00:00', '2020-01-01 23:59:59'
/*======================================================================================================================================================*/
