
-- RC00038

-- 3. Se define como regla, las calidad solicitada de `TRABAJADOR`, el trámite debe registrar una empresa.
-- =========================================================================================================================================================

-- 3.1
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Tramite] = tt.sDescripcion,
   [Estado Trámite] = ti.sEstadoActual,
   [Calidad Migratoria] = cm.sDescripcion,
   [Empresa] = ti.nIdOrganizacion

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND (ti.nIdOrganizacion IS NULL OR ti.nIdOrganizacion = '' OR ti.nIdOrganizacion = 0)
   AND ccm.nIdCalSolicitada IN (
      SELECT cm.nIdCalidad
      FROM SimCalidadMigratoria cm
      WHERE 
         cm.bActivo = 1
         AND cm.sDescripcion LIKE '%trab%'
   )


-- =============================================================================================================================================