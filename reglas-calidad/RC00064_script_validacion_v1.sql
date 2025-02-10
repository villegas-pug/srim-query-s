-- RC00064

-- 4. Se define como regla de calidad que los trámites que otorguen una calidad migratoria deben actualizar dicha calidad en los datos generales.
-- =====================================================================================================================================================================

-- 4.1. Calidad migratoria para: `Solicitud de Calidad Migratoria`.
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Número Trámite] = v.sNumeroTramite,
   [Fecha Inicio Vigencia] = v.dFechaAprobacion,
   [Fecha Fin Vigencia] = v.dFechaVencimiento,
   [Tipo Tiempo Otorgado] = v.sTipoTiempo,
   [Tiempo Otorgado] = v.nTiempo

FROM SimVisa v
JOIN SimTramite t ON v.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND 55 = ALL ( -- Únicamente `Solicitud de Visa`.
                  SELECT t2.nIdTipoTramite
                  FROM SimTramite t2
                  JOIN SimTramiteInm ti2 ON t2.sNumeroTramite = ti2.sNumeroTramite
                  WHERE
                     t2.bCancelado = 0
                     AND ti2.sEstadoActual = 'A'
                     AND t2.uIdPersona = t.uIdPersona
                  GROUP BY t2.nIdTipoTramite
   ) -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND v.dFechaVencimiento > GETDATE() -- Vigente
   AND ( -- Calidad actual distinta a solicitada
         SELECT pe.nIdCalidad 
         FROM SimPersona pe
         WHERE pe.uIdPersona = t.uIdPersona
   ) != v.nIdCalSolicitada

-- =====================================================================================================================================================================