USE SIM
GO

;WITH cte_dnv AS (
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

			[Siguiente_Tipo_MM] = LEAD(smm.sTipo) OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl),
			[Siguiente_Fecha_Control] = LEAD(smm.dFechaControl) OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl),

			-- [nCount_mm] = COUNT(1) OVER (PARTITION BY smm.uIdPersona), -- Aux field ...

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
			-- INTO #mm_dnv
			-- DROP TABLE IF EXISTS #mm_dnv
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
		-- AND sce.bAnulado = 0
		-- AND smm.sTipo = 'E'
		-- AND smm.dFechaControl BETWEEN '2022-06-14 00:00:00.000' AND '2022-06-16 23:59:59.999'
		AND smm.dFechaControl >= '2022-06-14 00:00:00.000'
		AND smm.sIdDependencia = '37' -- 37 |	PCF SANTA ROSA IQUITOS
		AND smm.sIdPaisNacionalidad IN ('COL', 'BRA') 
	-- ORDER BY sp.uIdPersona, smm.dFechaControl
) SELECT * FROM cte_dnv mm 
WHERE 
	-- mm.nCount_mm > 2
	mm.Tipo_Movimiento = 'E'
	AND mm.Fecha_Control BETWEEN '2022-06-14 00:00:00.000' AND '2022-06-16 23:59:59.999'
ORDER BY 
	mm.uIdPersona, mm.Fecha_Control

/*► Test ... */

-- COL | BRA
SELECT * FROM SimPais sp WHERE sp.sNombre LIKE 'bra%'

-- 37 |	PCF SANTA ROSA IQUITOS
SELECT * FROM dbo.SimDependencia sd WHERE sd.sNombre LIKE '%iquito%'



SELECT 
	TOP 100000
	uIdPersona,
	sPaterno,
	sMaterno,
	sNombre,
	sSexo,
	dFechaNacimiento,
	sObservaciones,
	bActivo,
	nIdCalidad,
	sIdPaisNacimiento,
	sIdPaisResidencia,
	sIdPaisNacionalidad
FROM SimPersona


