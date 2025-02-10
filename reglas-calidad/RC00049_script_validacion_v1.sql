-- RC00049

/* 
   4. Se define como regla que, solo los vuelos internacionales deben registrar un itinerario completo, que incluya información sobre la ruta de vuelo, pasajeros, carga y tripulación.
-- ===================================================================================================================================================================== */


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
   [Id Itinerario] = mm.sIdItinerario,
   [Fecha Programada] = i.dFechaProgramada,
   [Número Nave] = i.sNumeroNave,
   [Cantidad Pasajeros] = i.nCantidadMov,
   [Aerolinea] = et.sNombreRazon

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
JOIN SIM.dbo.SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdViaTransporte = 'A' -- A | AEREO
   -- AND mm.sIdItinerario IS NOT NULL
   AND mm.sIdDependencia NOT IN ( -- Dependencias para vuelos internaciones
                                    '27', -- 27 | A.I.J.CH.
                                    '24'  -- 24 | A.I.J.CH. DIA
   )
   

-- =====================================================================================================================================================================