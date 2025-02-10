-- RC00056

-- 5. Se define como regla, que cada ciudadano debe tener un único registro de control migratorio asociado a una sola vía de transporte.
-- =====================================================================================================================================================================

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
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Via Transporte] = t.sDescripcion
   
FROM (
   SELECT
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdViaTransporte,

      -- Aux
      [uid-yyyyMMd-HH-Tip] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo),
      [uid-yyyyMMd-HH-Tip-via] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo, mm.sIdViaTransporte)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimViaTransporte t ON f.sIdViaTransporte = t.sIdViaTransporte
WHERE
   f.[uid-yyyyMMd-HH-Tip] >= 2 -- Duplicados
   AND [uid-yyyyMMd-HH-Tip-via] = 1 -- Transportistas distintos


-- =====================================================================================================================================================================