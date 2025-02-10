-- RC00050

-- 1. Se define como regla que, la dependencia de Lima no debe tener registros de Control Migratorio.
-- =====================================================================================================================================================================

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
   [Dependencia] = d.sNombre,
   [Via Transporte] = mm.sIdViaTransporte

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia IN ('25') -- Lima
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- =====================================================================================================================================================================