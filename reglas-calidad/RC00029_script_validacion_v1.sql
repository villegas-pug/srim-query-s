-- RC00029
--> ░ 4. Se define como regla, que la emisión de carnet de extranjeria es para cada persona individualmente.
--> ░ 4. Distintos ciudadanos extranjeros, registran igual número de C.E en `SIM.dbo.SimCarnetExtranjeria`.
-- ========================================================================================================================================================================

-- 4.1
DROP TABLE IF EXISTS #tmp_dupl_ce
SELECT 
   f.*
   INTO #tmp_dupl_ce
FROM (

   SELECT

      ce.*,
      [sNombre(SimPersona)] = pe.sNombre,
      [sPaterno(SimPersona)] = pe.sPaterno,
      [sMaterno(SimPersona)] = pe.sMaterno,
      [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento,
      [sIdPaisNacionalidad(SimPersona)] = pe.sIdPaisNacionalidad,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY ce.uIdPersona, ce.sNumeroCarnet ORDER BY ce.dFechaEmision DESC),
      [nTotalCE] = COUNT(1) OVER (PARTITION BY ce.sNumeroCarnet)

   FROM SimCarnetExtranjeria ce
   JOIN SimTramite t ON t.sNumeroTramite = ce.sNumeroTramite
   JOIN SimPersona pe ON ce.uIdPersona = pe.uIdPersona
   WHERE
      t.bCancelado = 0
      AND (
            ISNUMERIC(ce.sNumeroCarnet) = 1
            AND LEN(ce.sNumeroCarnet) = 9
         )
   
) f
WHERE
   f.[#] = 1 -- Personas
   AND f.[nTotalCE] > 1 -- Total `CE`

-- 4.2. Final ...
SELECT COUNT(1)
FROM #tmp_dupl_ce
SELECT 

   [Id Persona] = f1.uIdPersona,
   [Nombres] = f1.[sNombre(SimPersona)],
   [Apellido 1] = f1.[sPaterno(SimPersona)],
   [Apellido 2] = f1.[sMaterno(SimPersona)],
   [Sexo] = '',
   [Fecha de Nacimiento] = f1.[dFechaNacimiento(SimPersona)],
   [Nacionalidad ] = f1.[sIdPaisNacionalidad(SimPersona)],

   -- Aux
   [Número Trámite] = f1.sNumeroTramite,
   [Fecha Emisión] = f1.dFechaEmision,
   [Número Carnet] = f1.sNumeroCarnet

FROM #tmp_dupl_ce f1
WHERE
   EXISTS (
            SELECT TOP 1 1
            FROM #tmp_dupl_ce f2
            WHERE
               f1.sNumeroCarnet = f2.sNumeroCarnet -- `CE` iguales ...
               AND f1.uIdPersona != f2.uIdPersona -- Persona distintas ...
   )
ORDER BY f1.sNumeroCarnet

-- ========================================================================================================================================================================