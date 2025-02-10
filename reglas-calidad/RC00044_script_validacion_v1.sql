-- RC00044

-- 4. Se define como regla que, si el control migratorio está activo, el itinerario no debe estar cancelado.
-- =====================================================================================================================================================================

-- 4.1
/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

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
   [Estado Movimiento] = IIF(mm.bAnulado = 0, 'Activo', 'Anulado'),
   [Estado Itinerario] = (
                              CASE
                                 WHEN (i.sEstado = 'X') THEN 'Cancelado'
                                 WHEN (i.sEstado = 'N') THEN 'Anulado'
                                 WHEN (i.sEstado = 'Z') THEN 'Cancelado Automático'
                              END
                        )
FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND i.sEstado IN ('X', 'N', 'Z')


-- =====================================================================================================================================================================