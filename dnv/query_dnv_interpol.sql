USE SIM
GO

/*░
	-- bActivo → 0: Habilitada; 1: Inhabilitada
   -- Extrae relación de alertas de lista de interpol ...
-- =============================================================================================================================================================== */

-- 1: ...
-- 1.1: Interpol ...
EXEC sp_help SimPersona
DROP TABLE IF EXISTS #tmp_dnv_interpol
SELECT 
   TOP 0
   [nId] = 0,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.sIdPaisNacionalidad
   INTO #tmp_dnv_interpol
FROM SimPersona sper

-- 1.2: Insert ...
-- INSERT INTO #tmp_dnv_interpol(col1, col2, col3)
-- SELECT COUNT(1) FROM #tmp_dnv_interpol

-- 1.3
DROP TABLE IF EXISTS #tmp_dnv_interpol_1_3
SELECT dnvi2.* INTO #tmp_dnv_interpol_1_3 FROM (

   SELECT 
      dnvi.*,
      [nFila] = ROW_NUMBER() OVER (PARTITION BY dnvi.sNombre, dnvi.sPaterno, dnvi.sMaterno, dnvi.sIdPaisNacionalidad ORDER BY dnvi.sNombre)
   FROM #tmp_dnv_interpol dnvi

) dnvi2
WHERE
   dnvi2.nFila = 1

-- Test ...
SELECT COUNT(1) FROM #tmp_dnv_interpol_1_3

-- 2: Final ...
DROP TABLE IF EXISTS #tmp_dnv_interpol_final
SELECT 
   i.nId,
	-- sper.uIdPersona,
	[sNumDocInvalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	[sNumDocIdentidad] = CONCAT('''', spna.sNumDocIdentidad),
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	-- sper.sCalidadMigratoria,
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
	spna.bActivo,
	[¿Nombre en observaciones?] = (
												CASE
													WHEN EXISTS(
														SELECT 1 FROM SimPersonaNoAutorizada dnv1
														WHERE
															dnv1.nIdDocInvalidacion = spna.nIdDocInvalidacion
															AND dnv1.sObservaciones LIKE '%' + i.sNombre + '%'
													) THEN 'SI'
													WHEN EXISTS(
														SELECT 1 FROM SimDocInvalidacion dnv2
														WHERE
															dnv2.nIdDocInvalidacion = spna.nIdDocInvalidacion
															AND dnv2.sObservaciones LIKE '%' + i.sNombre + '%'
													) THEN 'SI'
													ELSE 'NO'
												END
											)
	
	INTO #tmp_dnv_interpol_final
FROM #tmp_dnv_interpol_1_3 i
LEFT JOIN SimPersonaNoAutorizada spna ON i.sNombre = spna.sNombre 
                                      AND i.sPaterno = spna.sPaterno 
                                      AND i.sMaterno = spna.sMaterno 
                                      AND i.sIdPaisNacionalidad = spna.sIdPaisNacionalidad
LEFT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimSesion ss ON sdi.nIdSesion = ss.nIdSesion
LEFT JOIN SimModulo sm ON ss.sIdModulo = sm.sIdModulo
LEFT JOIN SimUsuario su ON ss.nIdOperador = su.nIdOperador
LEFT JOIN SimOrganigrama so ON su.sCodigoArea = so.sCodigoArea
LEFT JOIN SimDependencia sd ON su.sIdDependencia = sd.sIdDependencia
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
	spna.bActivo = 1 -- Inhabilitada ...
   AND spna.sObservaciones LIKE '%INTERPOL%'

-- Test ...
SELECT * FROM #tmp_dnv_interpol_final
SELECT COUNT(1) FROM #tmp_dnv_interpol_final
-- =============================================================================================================================================================== */