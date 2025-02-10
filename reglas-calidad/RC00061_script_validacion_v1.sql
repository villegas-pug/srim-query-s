-- RC00061

-- 1. Se define como regla de calidad que los países sin límites marítimos no podrán realizar movimientos migratorios de entradas o salidas a través de via transporte marítimo.
-- =======================================================================================================================================================================================

-- 1.
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Tipo Movimiento] = sm.sTipo,
   [Fecha Control] = sm.dFechaControl,
   [Via Transporte] = sm.sIdViaTransporte,
   [Pais Movimiento] = sm.sIdPaisMov,
   [Dependencia] = sm.sIdDependencia

FROM SimMovMigra sm
JOIN SimPersona pe ON sm.uIdPersona = pe.uIdPersona
WHERE
      sm.[bAnulado] = 0 
      AND sm.[bTemporal] = 0
      AND sm.[sIdViaTransporte] = 'M' -- Via de transporte
      AND sm.[sIdPaisMov] IN ('BOL', 'PAR') -- Sin límites marítimos
      AND sm.[dFechaControl] >= '2010-01-01 00:00:00.000'

-- =======================================================================================================================================================================================