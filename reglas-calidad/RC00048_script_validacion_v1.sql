-- RC00048

-- 3. Se define como regla que, los registros de control migratorio deben registrar explícitamente una dependencia.
-- =====================================================================================================================================================================


-- 3.1 Modulo digita NULL
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
   [Dependencia] = d.sNombre

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = 'NNN'

-- =====================================================================================================================================================================