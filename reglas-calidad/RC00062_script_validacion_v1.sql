-- RC00062
-- 2. Se define como regla de calidad que los países asociados al continente europeo no deberán registrar movimientos migratorios a través del transporte terrestre.
-- =======================================================================================================================================================================================

-- 2
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Tipo Movimiento] = mm.sTipo,
   [Fecha Control] = mm.dFechaControl,
   [Via Transporte] = mm.sIdViaTransporte,
   [Pais Movimiento] = mm.sIdPaisMov,
   [Dependencia] = mm.sIdDependencia

FROM SimMovMigra mm
JOIN SimPais ps on mm.sIdPaisMov = ps.sIdPais
JOIN SimPersona pe on  mm.uIdPersona = pe.uIdPersona
JOIN SimContinente con on ps.nIdContinente = con.nIdContinente
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND con.nIdContinente = 8
   AND mm.sIdViaTransporte = 'T'
   AND mm.[dFechaControl] >= '2016-01-01 00:00:00.000'

-- ======================================================================================================================================================================================= */