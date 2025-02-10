-- RC00025

-- 10. Se define como regla, que únicamente ciudadanos menores de edad podrían realizar control migratorio con documento de viaje PNA(Partida de nacimiento).
-- ======================================================================================================================================================================== */

-- 10.1
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   --- Aux   
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Documento Viaje] = mm.sIdDocumento,
   [Número Documento] = mm.sNumeroDoc,
   [Tipo Control] = mm.sTipo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Fecha Control] = mm.dFechaControl,
   [Edad (Control Migratorio)] = DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl),
   [Pais Nacionalidad] = mm.sIdPaisNacionalidad

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona p ON mm.uIdPersona = p.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sTipo = 'E'
   -- AND (mm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND mm.sIdPaisNacionalidad IS NOT NULL)
   AND mm.sIdDocumento = 'PNA' -- PNA | PARTIDA DE NACIMIENTO
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   AND DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl) >= 18 -- Mayores de edad

-- ======================================================================================================================================================================== */