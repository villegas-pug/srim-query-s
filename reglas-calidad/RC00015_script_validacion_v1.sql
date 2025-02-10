-- RC00015
-- 5. Control migratorio de ciudadanos con Calidad Migratoria `PERUANO` y tipo de documento de viaje `CIP`.
-- ======================================================================================================================================================================== */

-- 21 ↔ PERUANO
-- CIP ↔ DOC. IDENTIFICACION PERSONAL
SELECT 

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

      -- Aux
   mm.dFechaControl,
   mm.sTipo,
   [sCalidadMigratoria] = cm.sDescripcion,
   mm.sIdPaisMov
FROM SimMovMigra mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sTipo = 'E'
   AND mm.sIdDocumento = 'CIP'-- CIP ↔ DOC. IDENTIFICACION PERSONAL
   AND mm.sIdPaisNacionalidad = 'PER'
   AND mm.nIdCalidad = 21 -- 21 ↔ PERUANO


-- ======================================================================================================================================================================== */