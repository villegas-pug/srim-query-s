-- RC00027

--> ░ 2. Se define como regla, que el país de procedencia o destino registrado en el Control Migratorio debe coincidir con el país de procedencia o destino registrado en el Itinerario.
-- ========================================================================================================================================================================

-- 2.1
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha de Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad ] = pe.sIdPaisNacionalidad,

   -- Aux
   mm.sIdMovMigratorio,
   mm.dFechaControl,
   mm.sTipo,
   [Itinerario(SimMovMigra)] = mm.sIdItinerario,
   [Pais Movimiento(SimMovMigra)] = mm.sIdPaisMov,
   [Itinerario(SimItinerario)] = i.sIdItinerario,
   [Pais Movimiento(SimItinerario)] = i.sIdPais
   
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sIdPaisMov != 'NNN' AND i.sTipoMovimiento != 'NNN')
   AND mm.sIdPaisMov != i.sIdPais -- Distinto pais de Proc/Dest
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- ========================================================================================================================================================================