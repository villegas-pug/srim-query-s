-- RC00010
-- 4. Se registran Calidad anterior y solicitada iguales ...
-- ==================================================================================================================================================================

-- Identificar inconsitencia.
DROP TABLE IF EXISTS #tmp_Calant_igual_calsol
SELECT 
   
   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- Aux
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalAnterior,
   [sCalidadAnterion] = cma.sDescripcion,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion
   INTO #tmp_Calant_igual_calsol
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   -- 314 ↔ ACUERDOS INTERNACIONALES - MERCOSUR; 332 ↔ MERCOSUR PERMANENTE
   AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))
   AND ccm.nIdCalAnterior = ccm.nIdCalSolicitada
ORDER BY
   t.dFechaHora DESC