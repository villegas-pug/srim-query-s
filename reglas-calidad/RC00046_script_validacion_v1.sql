-- RC00046

-- 1. Se define como regla que, todos los vuelos registrados en el A.I.J.C.H., deben tener un itinerario asociado y registrado en el sistema.
-- ================================================================================================================================================

-- 1.1 
SELECT
   TOP 10
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
   [Pais Origen/Destino] = mm.sIdPaisMov,
   [Id Itinerario] = mm.sIdItinerario,
   [Via Transporte] = mm.sIdViaTransporte

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia IN (
                              '27', -- 27 | A.I.J.CH.
                              '24'  -- 24 | A.I.J.CH. DIA
                           )
   -- AND mm.sIdViaTransporte = 'A' -- A | AEREO
   AND mm.dFechaControl >= '2019-01-01 00:00:00.000'
   AND mm.sIdItinerario IS NULL
ORDER BY mm.dFechaControl DESC

-- =========================================================================================================================================================