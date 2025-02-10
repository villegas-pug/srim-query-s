-- RC00043

-- 3. Se define como regla que, el país de destino del movimiento migratorio de salida debe ser diferente a Perú.
-- =====================================================================================================================================================================

-- 3.1
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Pais Movimiento] = mm.sIdPaisMov

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'S'
   AND mm.sIdPaisMov = 'PER'
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- 3.2 Script detección.
SELECT 
   mm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'S'
   AND mm.sIdPaisMov = 'PER'

-- =====================================================================================================================================================================