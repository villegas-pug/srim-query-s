-- RC00023
-- 8. Se establece como regla de calidad que los datos personales registrados en la emisión de pasaportes deben coincidir exactamente con los registrados en el trámite correspondiente.
-- ======================================================================================================================================================================== */

-- 90 ↔ Expedición de Pasaporte Electrónico

-- 8.1
-- 8.1.1
DROP TABLE IF EXISTS #tmp_pas_j_per
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha de Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad ] = pe.sIdPaisNacionalidad,

   -- Pas
   [uIdPersona(SimPasaporte)] = t.uIdPersona,
   [sPasNumero(SimPasaporte)] = p.sPasNumero,
   [sNombre(SimPasaporte)] = LTRIM(RTRIM(p.sNombre)),
   [sPaterno(SimPasaporte)] = LTRIM(RTRIM(p.sPaterno)),
   [sMaterno(SimPasaporte)] = LTRIM(RTRIM(p.sMaterno)),

   -- Per
   [uIdPersona(SimPersona)] = pe.uIdPersona,
   [sNombre(SimPersona)] = LTRIM(RTRIM(pe.sNombre)),
   [sPaterno(SimPersona)] = LTRIM(RTRIM(pe.sPaterno)),
   [sMaterno(SimPersona)] = LTRIM(RTRIM(pe.sMaterno))

   INTO #tmp_pas_j_per
FROM SimTramitePas p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND pe.bActivo = 1
   AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico

-- 8.1.2
SELECT pp.* FROM #tmp_pas_j_per pp
WHERE
   (
      DIFFERENCE(pp.[sNombre(SimPersona)], pp.[sNombre(SimPasaporte)]) <= 3
      AND DIFFERENCE(pp.[sPaterno(SimPersona)], pp.[sPaterno(SimPasaporte)]) <= 3
      AND DIFFERENCE(pp.[sMaterno(SimPersona)], pp.[sMaterno(SimPasaporte)]) <= 3
   )