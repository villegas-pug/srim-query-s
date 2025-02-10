-- RC00024
-- 9. Registros de Control Migratorio duplicados en tipo de movimiento, fecha de control, hora, minuto y segundo.
-- ======================================================================================================================================================================== */

-- 9.1
SELECT 

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm2.sIdMovMigratorio,
   [Fecha Control] = mm2.dFechaControl,
   [Tipo] = mm2.sTipo,
   [Pais Nacionalidad] = mm2.sIdPaisNacionalidad

FROM (

   SELECT 
      mm.*,
      -- [nDupl] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sTipo, CONVERT(VARCHAR(16), mm.dFechaControl, 120)) -- HH:mm
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY 
                                       mm.uIdPersona, 
                                       mm.sTipo, 
                                       CONVERT(VARCHAR(16), mm.dFechaControl, 120)
                                 ) -- yyyy-MM-dd HH:mm
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) mm2
JOIN SimPersona p ON mm2.uIdPersona = p.uIdPersona
WHERE
   mm2.nDupl >= 2