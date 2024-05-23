-- ============================================================================================================
-- Entrada : 30/05/2022
-- País de procedencia: Bolivia
-- Ingreso por P.C : CEBAF TUMBES / CEBAF PERU
-- ============================================================================================================
/*--------------------------------------------------------------------------------------------------------------------------------------------*/
USE SIM
GO

SELECT 
	dnv.*,
	
	[MENOR 10 DIAS] = (
							CASE 
								WHEN
									(SELECT TOP 1 DATEDIFF(DD,
														   LEAD(dFechaControl) OVER (ORDER BY dFechaControl DESC),
														   FIRST_VALUE(dFechaControl) OVER (ORDER BY dFechaControl DESC))
									FROM SimMovMigra
									WHERE uIdPersona = dnv.uIdPersona) < 10 THEN 'Si'
								ELSE 'No'
							END
					 ),
	[RUTA] = (
					SELECT 
						TOP 1
						COALESCE(LEAD(sIdPaisMov) OVER (ORDER BY dFechaControl DESC), 'SIN ENTRADA') + '-PER-' + FIRST_VALUE(sIdPaisMov) OVER (ORDER BY dFechaControl DESC)
					FROM SimMovMigra
					WHERE uIdPersona = dnv.uIdPersona
			),
	[CALIDAD MIGRATORIA] = (

								SELECT 
									TOP 1
									FIRST_VALUE(scm.sDescripcion) OVER (ORDER BY dFechaControl DESC)
								FROM SimMovMigra
								JOIN SimCalidadMigratoria scm ON SimMovMigra.nIdCalidad = scm.nIdCalidad
								WHERE uIdPersona = dnv.uIdPersona
	
						   ),
	[FECHA VENCIMIENTO RESIDENCIA] = CONVERT(VARCHAR,
											(
												SELECT 
													TOP 1
													DATEADD(DD,
															LEAD(nPermanencia) OVER (ORDER BY dFechaControl DESC),
															LEAD(dFechaControl) OVER (ORDER BY dFechaControl DESC))
												FROM SimMovMigra
												WHERE uIdPersona = dnv.uIdPersona
											),
											103
								     ),
	[ULTIMO MOVIMIENTO] = (
								SELECT 
									TOP 1
									FIRST_VALUE(sTipo) OVER (ORDER BY dFechaControl DESC)
								FROM SimMovMigra
								WHERE uIdPersona = dnv.uIdPersona
							),
	[FECHA ULTIMO MOVIMIENTO] = CONVERT(VARCHAR,
										(
											SELECT 
											TOP 1
											FIRST_VALUE(dFechaControl) OVER (ORDER BY dFechaControl DESC)
											FROM SimMovMigra
											WHERE uIdPersona = dnv.uIdPersona
										),
										103
								)

FROM (
	SELECT
		-- Group-01
		nRow_MM = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC),
		smm.uIdPersona,
		(smm.sIdDocumento)Documento,
		[Num_Doc] = CONCAT('''', smm.sNumeroDoc),
		(sp.sNombre)Nombre,
		(sp.sPaterno)Ape_Paterno,
		(sp.sMaterno)Ape_Materno,
		(sp.sSexo)Sexo,
		[Fec_Nacimiento] = CONVERT(VARCHAR, sp.dFechaNacimiento, 103),
		(spnacionalidad.sNombre)Pais_Nacionalidad,
		(sd.sNombre)Dep_Digita,
		(sprof.sDescripcion)Ocupacion,
		(sorg.sNombre)Razon_Social_Empresa,
		(sorg.sNumeroDoc)Ruc_Empresa,
		(smm.sObservaciones)Observaciones_SIM_RCM,

		[Tipo_Mov] = smm.sTipo -- Reservado para filtro ...
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
		AND smm.sIdPaisNacionalidad = 'RUS'
		AND smm.dFechaControl BETWEEN '2022-01-01 00:00:00.000' AND '2022-11-15 23:59:59.999'
) dnv 
WHERE 
	dnv.nRow_MM = 1
	AND dnv.Tipo_Mov = 'S'

-- Test ...

-- =================================================================================================================================================================================

-- =================================================================================================================================================================================
-- ► DNV v1.1 */
-- =================================================================================================================================================================================
USE SIM
GO

SELECT 
	dnv.*
FROM (
	SELECT
		-- Group-01
		nRow_MM = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC),
		smm.uIdPersona,
		(smm.sIdDocumento)Documento,
		[Num_Doc] = CONCAT('''', smm.sNumeroDoc),
		(sp.sNombre)Nombre,
		(sp.sPaterno)Ape_Paterno,
		(sp.sMaterno)Ape_Materno,
		(sp.sSexo)Sexo,
		[Fec_Nacimiento] = CONVERT(VARCHAR, sp.dFechaNacimiento, 103),
		(spnacionalidad.sNombre)Pais_Nacionalidad,
		(smm.sTipo)Tipo_Mov,
		[Fec_Control] = CONVERT(VARCHAR, smm.dFechaControl, 103),
		(sd.sNombre)Dep_Digita,
		(scm.sDescripcion)MovMig_Calidad_Migratoria,
		(sprof.sDescripcion)Ocupacion,
		(sorg.sNombre)Razon_Social_Empresa,
		(sorg.sNumeroDoc)Ruc_Empresa,
		(smm.sObservaciones)Observaciones_SIM_RCM
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
		AND smm.sIdPaisNacionalidad = 'RUS'
		AND smm.dFechaControl BETWEEN '2022-01-01 00:00:00.000' AND '2022-11-15 23:59:59.999'
) dnv 
WHERE 
	dnv.nRow_MM = 1
	AND dnv.Tipo_Mov = 'E'

-- Test ...
SELECT * FROM SimPais p
WHERE
	p.sNombre LIKE '%rus%'-- TUR | TURQUIA - TLD | TAILANDIA
-- =================================================================================================================================================================================

SELECT QUOTENAME('rguevarav', ',')

DECLARE @fields NVARCHAR(MAX) = ''
SELECT
	TOP 10
	@fields += QUOTENAME(sp.sNombre) + ','
FROM SimPais sp

SELECT @fields

SELECT * FROM SimPais sp
	