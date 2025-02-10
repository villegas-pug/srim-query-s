-- RC00041

-- 1. Se define como regla que, la dependencia A.I.J.C.H. únicamente debe registrar transporte aéreo.
-- =====================================================================================================================================================================

-- 1.1 
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
   [Via Transporte] = t.sDescripcion,
   [Dependencia] = d.sNombre

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimViaTransporte t ON mm.sIdViaTransporte = t.sIdViaTransporte
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 | A.I.J.CH.
   AND mm.sIdViaTransporte != 'A'  -- A | AEREO
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   AND mm.bMigrado = 0


-- =========================================================================================================================================================