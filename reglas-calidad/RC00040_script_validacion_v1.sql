-- RC00040

-- 5. Se define como regla, que únicamente paises que forman parte de comunidad Andina, pueden registrar un documento de viaje `TAM`.
-- =============================================================================================================================================
-- 5.1
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
   [Tipo Movimiento] = mm.sTipo,
   [Fecha Movimiento] = mm.dFechaControl,
   [Documento] = mm.sIdDocumento,
   [Número Documento] = mm.sNumeroDoc,
   [Dependencia] = d.sNombre

FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento = 'TAM' -- TAM | TARJETA ANDINA | 1567
   AND mm.sIdPaisNacionalidad NOT IN ('PER', 'ECU', 'CHL', 'BOL', 'ARN', 'ESP', 'BRA', 'COL')
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
-- =============================================================================================================================================