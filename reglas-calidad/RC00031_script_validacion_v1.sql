-- RC00031

--> ░ 1. Se define como regla, que el control migratorio por e-gates solo debe ser utilizado por ciudadanos peruanos que cuenten con documentos de viaje PAS electrónico. ...
-- ========================================================================================================================================================================

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
   [Dependencia] = d.sNombre,
   [Módulo] = mm.sIdModuloDigita

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
-- JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdModuloDigita = 'EGATES' -- EGATES | EGATES
   AND mm.sIdDocumento != 'PAS' -- Documento viaje
   AND mm.sNumeroDoc NOT LIKE '1[1-2]%' -- Documento viaje
   -- AND pe.sIdPaisNacionalidad = 'PER' -- Peruano
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- ========================================================================================================================================================================