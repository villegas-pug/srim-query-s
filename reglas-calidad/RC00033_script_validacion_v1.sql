-- RC00033

--> ░ 3. Se define como regla, que las `Solicitud de Cambio Calidad Migratoria` Aprobadas, deben registrar una fecha de vencimiento ...
-- ========================================================================================================================================================================

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Fecha Trámite] = t.dFechaHora,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado] = ti.sEstadoActual,
   [dFechaAprobacion] = v.dFechaAprobacion,
   [dFechaVencimiento] = v.dFechaVencimiento

FROM SimVisa v
JOIN SimTramite t ON v.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite = 55 -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND (v.dFechaVencimiento IS NULL OR v.dFechaVencimiento = '1900-01-01 00:00:00.000' OR v.dFechaVencimiento = '') -- Fecha nula, fecha invalida o vacia ...
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'


-- ========================================================================================================================================================================