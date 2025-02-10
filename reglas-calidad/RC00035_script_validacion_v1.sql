-- RC00035

--	5. Se define como regla, que la población extranjera menor de edad, no debe registrar una calidad migratoria de: `ARTISTA, TRIPULANTE, NEGOCIOS y TRABAJADOR`.
-- ============================================================================================================================================================

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Fecha Control] = mm.dFechaControl,
   [Edad Control] = DATEDIFF(YYYY, pe.dFechaNacimiento, mm.dFechaControl),
   [Tipo Control] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
   [Calidad Migratoria Control] = cm.sDescripcion
   
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND DATEDIFF(YYYY, pe.dFechaNacimiento, mm.dFechaControl) < 18 -- Menores
   AND mm.nIdCalidad IN ( -- 'OFICIAL', 'ARTISTA', 'TRIPULANTE', 'NEGOCIOS', 'TRABAJADOR', 'DIPLOMATICA'
         '58', '191', '212', '245', '246', '247', '266', '267', '292', '300', '316'
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

--============================================================================================================================================================