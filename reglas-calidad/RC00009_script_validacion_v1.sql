-- RC00009
--> 3. Trámites de Cambio de Calidad en estado aprobado, sin fecha de aprobación.
-- ==================================================================================================================================================================

-- EXEC sp_help SimCambioCalMig
SELECT 

   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- AUx
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion,
   ccm.dFechaAprobacion
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (
      58  -- CCM
      -- 113, -- REGULARIZACION DE EXTRANJEROS
      -- 126  -- PERMISO TEMPORAL DE PERMANENCIA - RS109
   )
   AND ccm.dFechaAprobacion IS NULL
   

-- ==================================================================================================================================================================
