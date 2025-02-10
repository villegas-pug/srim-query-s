-- RC00058

-- 7. Se define como regla, que un operador no debe realizar el registro de control migratorio en más de una dependencia en la misma fecha, hora y minuto.
-- =====================================================================================================================================================================

-- 7.1
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Dependencia] = d.sNombre,
   [Operador Digita] = u.sLogin
   
FROM (

   SELECT

      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.nIdOperadorDigita,
      mm.sIdDependencia,

      -- Aux
      [nIdOpe-yyyyMMddHHmm] = COUNT(1) OVER (PARTITION BY 
                                                   mm.nIdOperadorDigita, 
                                                   -- FORMAT(mm.dFechaControl, 'yyyyMMddHHmm')
                                                   DATEADD(MINUTE, DATEDIFF(MINUTE, 0, mm.dFechaControl), 0)
                                             ),
      [nIdOpe-yyyyMMddHHmm-dep] = COUNT(1) OVER (PARTITION BY 
                                                      mm.nIdOperadorDigita, 
                                                      -- FORMAT(mm.dFechaControl, 'yyyyMMddHHmm'), 
                                                      DATEADD(MINUTE, DATEDIFF(MINUTE, 0, mm.dFechaControl), 0),
                                                      mm.sIdDependencia
                                                )

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'

) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON f.sIdDependencia = d.sIdDependencia
JOIN SimUsuario u ON f.nIdOperadorDigita = u.nIdOperador
WHERE
   f.[nIdOpe-yyyyMMddHHmm] = 2 -- Duplicados por operador
   AND f.[nIdOpe-yyyyMMddHHmm-dep] = 1 -- Dependencias distintas

-- =====================================================================================================================================================================