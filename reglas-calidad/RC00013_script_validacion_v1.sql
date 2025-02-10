
-- RC00013
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = mm.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Calidad Migratoria] = cm.sDescripcion,
   [Id Dependencia] = d.sSigla,
   [Dependencia] = d.sNombre

FROM SimMovMigra mm 
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
JOIN SimDependencia d On mm.sIdDependencia = d.sIdDependencia
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.nIdCalidad IN ( -- TURISTA
                           SELECT cm.nIdCalidad 
                           FROM SimCalidadMigratoria cm 
                           WHERE 
                              cm.bActivo = 1
                              AND cm.sDescripcion LIKE '%turi%'
   )
   AND (mm.sIdPaisNacionalidad = 'NNN' OR mm.sIdPaisNacionalidad IS NULL)
